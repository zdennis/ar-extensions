begin 
  require 'faster_csv'
  require 'ar-extensions/csv'
rescue LoadError => ex
  STDERR.puts "FasterCSV is not installed. CSV functionality will not be included."
  raise ex
end


# Adds CSV export options to ActiveRecord::Base models. 
#
# === Example 1, exporting all fields
#  class Book < ActiveRecord::Base ; end
#  
#  book = Book.find( 1 )
#  book.to_csv
#
# === Example 2, only exporting certain fields
#  class Book < ActiveRecord::Base ; end
#
#  book = Book.find( 1 ) 
#  book.to_csv( :only=>%W( title isbn )
#
# === Example 3, exporting a model including a belongs_to association
#  class Book < ActiveRecord::Base 
#    belongs_to :author
#  end
# 
#  book = Book.find( 1 )
#  book.to_csv( :include=>:author )
#
# This also works for a has_one relationship. The :include
# option can also be an array of has_one/belongs_to 
# associations. This by default includes all fields
# on the belongs_to association.
#
# === Example 4, exporting a model including a has_many association
#  class Book < ActiveRecord::Base 
#    has_many :tags
#  end
# 
#  book = Book.find( 1 )
#  book.to_csv( :include=>:tags )
#
# This by default includes all fields on the has_many assocaition.
# This can also be an array of multiple has_many relationships. The
# array can be mixed with has_one/belongs_to associations array
# as well. IE: :include=>[ :author, :sales ]
#
# === Example 5, nesting associations
#  class Book < ActiveRecord::Base 
#    belongs_to :author
#    has_many :tags
#  end
#
#  book = Book.find( 1 )
#  book.to_csv( :includes=>{ 
#                  :author => { :only=>%W( name ) },
#                  :tags => { :only=>%W( tagname ) } )
#
# Each included association can receive an options Hash. This
# allows you to nest the associations as deep as you want 
# for your CSV export. 
#
# It is not recommended to nest multiple has_many associations, 
# although nesting multiple has_one/belongs_to associations.
#
module ActiveRecord::Extensions::FindToCSV

  def self.included(base)
    if !base.respond_to?(:find_with_csv)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods        
      end
      class << base
        alias_method_chain :find, :csv
      end
    end
  end
  
  class FieldMap# :nodoc:
    attr_reader :fields, :fields_to_headers
 
    def initialize( fields, fields_to_headers ) # :nodoc:
      @fields, @fields_to_headers = fields, fields_to_headers
    end
    
    def headers # :nodoc:
      @headers ||= fields.inject( [] ){ |arr,field| arr << fields_to_headers[ field ] }
    end
    
  end

  module ClassMethods # :nodoc:      
    private

    def to_csv_fields_for_nil # :nodoc:
      self.columns.map{ |column| column.name }.sort
    end                         

    def to_csv_headers_for_included_associations( includes ) # :nodoc:
      get_class = proc { |str| Object.const_get( self.reflections[ str.to_sym ].class_name ) }

      case includes
      when Symbol
        [ get_class.call( includes ).to_csv_headers( :headers=>true, :naming=>":model[:header]" ) ]
      when Array
        includes.map do |association| 
          clazz = get_class.call( association )
          clazz.to_csv_headers( :headers=>true, :naming=>":model[:header]" )
        end
      when Hash
        includes.sort_by{ |k| k.to_s }.inject( [] ) do |arr,(association,options)|
          clazz = get_class.call( association )
          if options[:headers].is_a?( Hash )
            options.merge!( :naming=>":header" ) 
          else
            options.merge!( :naming=>":model[:header]" ) 
          end
          arr << clazz.to_csv_headers( options )
        end
      else
        []
      end
    end
    
    public

    def find_with_csv( *args ) # :nodoc:
      results = find_without_csv( *args )
      results.extend( ArrayInstanceMethods ) if results.is_a?( Array )
      results
    end

    def to_csv_fields( options={} ) # :nodoc:
      fields_to_headers, fields = {}, []
      
      headers = options[:headers]
      case headers
      when Array
        fields = headers.map{ |e| e.to_s }
      when Hash
        headers = headers.inject( {} ){ |hsh,(k,v)| hsh[k.to_s] = v ; hsh }
        fields = headers.keys.sort
        fields.each { |field| fields_to_headers[field] = headers[field] }
      else
        fields = to_csv_fields_for_nil
      end
      
      if options[:only]
        specified_fields = options[:only].map{ |e| e.to_s }
        fields.delete_if{ |field| not specified_fields.include?( field ) }
      elsif options[:except]
        excluded_fields = options[:except].map{ |e| e.to_s }
        fields.delete_if{ |field| excluded_fields.include?( field ) }
      end

      fields.each{ |field| fields_to_headers[field] = field } if fields_to_headers.empty?

      FieldMap.new( fields, fields_to_headers )
    end
    
    # Returns an array of CSV headers passed in the array of +options+.
    def to_csv_headers( options={} )
      options = { :headers=>true, :naming=>":header" }.merge( options )
      return nil if not options[:headers]

      fieldmap = to_csv_fields( options )
      headers = fieldmap.headers
      headers.push( *to_csv_headers_for_included_associations( options[ :include ] ).flatten )
      headers.map{ |header| options[:naming].gsub( /:header/, header ).gsub( /:model/, self.name.downcase ) }
    end

  end

  
  module InstanceMethods

    private
    
    def add_to_csv_association_methods!(association_name)
      association = self.send association_name
      association.send( :extend, ArrayInstanceMethods ) if association.is_a?( Array )
      association      
    end
    
    def add_to_csv_association_data! data, to
      if to.empty?
        to.push( *data )
      else
        originals = to.dup
        to.clear
        data.each do |assoc_csv|
          originals.each do |sibling|
            to.push( sibling + assoc_csv )
          end
        end
      end
    end
    
    def to_csv_association_is_blank?(association)
      association.nil? or (association.respond_to?( :empty? ) and association.empty?)      
    end
    
    def to_csv_data_for_included_associations( includes ) # :nodoc:
      get_class = proc { |str| Object.const_get( self.class.reflections[ str.to_sym ].class_name ) }

      case includes
      when Symbol
        association = add_to_csv_association_methods! includes
        if to_csv_association_is_blank?(association)
          [ get_class.call( includes ).columns.map{ '' } ]
        else
          [ *association.to_csv_data ]
        end
      when Array
        siblings = []
        includes.each do |association_name|
          association = add_to_csv_association_methods! association_name
          if to_csv_association_is_blank?(association)
            association_data = [ get_class.call( association_name ).columns.map{ '' }  ]
          else
            association_data = association.to_csv_data
          end

          add_to_csv_association_data! association_data, siblings
        end
        siblings
      when Hash
        sorted_includes = includes.sort_by{ |k| k.to_s }
        siblings = []
        sorted_includes.each do |(association_name,options)|
          association = add_to_csv_association_methods! association_name
          if to_csv_association_is_blank?(association)
            association_data = [ get_class.call( association_name ).columns.map{ '' }  ]
          else
            association_data = association.to_csv_data( options )
          end
          add_to_csv_association_data! association_data, siblings
        end
        siblings
      else
        []
      end
    end
    
    public
    
    # Returns CSV data without any header rows for the passed in +options+.
    def to_csv_data( options={} )
      fields = self.class.to_csv_fields( options ).fields
      data, model_data = [], fields.inject( [] ) { |arr,field| arr << attributes[field].to_s }
      if options[:include]
        to_csv_data_for_included_associations( options[:include ] ).map do |assoc_csv_data|
          data << model_data + assoc_csv_data
        end
      else
        data << model_data
      end
      data
    end
    
    # Returns CSV data including header rows for the passed in +options+.
    def to_csv( options={} )
      FasterCSV.generate do |csv|
        headers = self.class.to_csv_headers( options )
        csv << headers if headers
        to_csv_data( options ).each{ |data| csv << data }
      end
    end
    
  end

  module ArrayInstanceMethods # :nodoc:
    class NoRecordsError < StandardError ; end #:nodoc:

    # Returns CSV headers for an array of ActiveRecord::Base
    # model objects by calling to_csv_headers on the first
    # element.
    def to_csv_headers( options={} ) 
      first.class.to_csv_headers( options )
    end

    # Returns CSV data without headers for an array of
    # ActiveRecord::Base model objects by iterating over them and
    # calling to_csv_data with the passed in +options+.
    def to_csv_data( options={} )
      inject( [] ) do |arr,model_instance|
        arr.push( *model_instance.to_csv_data( options ) )
      end
    end

    # Returns CSV data with headers for an array of ActiveRecord::Base
    # model objects by iterating over them and calling to_csv with
    # the passed in +options+.
    def to_csv( options={} )
      FasterCSV.generate do |csv|
        headers = to_csv_headers( options )
        csv << headers if headers
        each do |model_instance| 
          model_instance.to_csv_data( options ).each{ |data| csv << data }
        end
      end
    end
    
  end

end
