require 'faster_csv'
require 'ostruct'

module ActiveRecord::Extensions::FindToCSV
  ALIAS_FOR_FIND = :_original_find_before_arext

  def self.included( cl )
    virtual_class = class << cl ; self ; end
    if not virtual_class.ancestors.include?( self::ClassMethods )
      cl.instance_eval "alias #{ALIAS_FOR_FIND} :find"
      cl.extend( ClassMethods )
      cl.send( :include, InstanceMethods )
    end
  end

  
  class FieldMap
    attr_reader :fields, :fields_to_headers
 
    def initialize( fields, fields_to_headers )
      @fields, @fields_to_headers = fields, fields_to_headers
    end
    
    def headers
      @headers ||= fields.inject( [] ){ |arr,field| arr << fields_to_headers[ field ] }
    end
    
  end

  
  module ClassMethods
      
    private

    def to_csv_fields_for_nil
      self.columns.map{ |column| column.name }.sort
    end                         

    def to_csv_headers_for_included_associations( includes )
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

    def find( *args )
      results = self.send( ALIAS_FOR_FIND, *args )
      results.extend( ArrayInstanceMethods ) if results.is_a?( Array )
      results
    end

    def to_csv_fields( options={} )
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
    
    def to_csv_data_for_included_associations( includes )
      get_class = proc { |str| Object.const_get( self.class.reflections[ str.to_sym ].class_name ) }

      case includes
      when Symbol
        association = self.send( includes )
        association.send( :extend, ArrayInstanceMethods ) if association.is_a?( Array )
        if association.nil?
          [ get_class.call( includes ).columns.map{ '' } ]
        else
          [ *association.to_csv_data ]
        end
      when Array
        siblings = []
        includes.each do |association_name|
          association = self.send( association_name )
          association.send( :extend, ArrayInstanceMethods ) if association.is_a?( Array )
          if association.nil?
            association_data = [ get_class.call( association_name ).columns.map{ '' }  ]
          else
            association_data = association.to_csv_data
          end

          if siblings.empty?
            siblings.push( *association_data )
          else
            temp = []
            association_data.each do |assoc_csv|
              siblings.each do |sibling|
                temp.push( sibling + assoc_csv )
              end
            end
            siblings = temp            
          end
        end
        siblings
#
#        includes.inject( [] ) do |arr,association_name| 
#          association = self.send( association_name )
#          association.send( :extend, ArrayInstanceMethods ) if association.is_a?( Array )
#          if association.nil?
#            arr.push( get_class.call( association_name ).columns.map{ '' } )
#          else
#            arr.push( *association.to_csv_data )
#          end
#        end
      when Hash
        sorted_includes = includes.sort_by{ |k| k.to_s }
        siblings = []
        sorted_includes.each do |(association_name,options)|
          association = self.send( association_name )
          association.send( :extend, ArrayInstanceMethods ) if association.is_a?( Array )
          if association.nil?
            association_data = [ get_class.call( association_name ).columns.map{ '' }  ]
          else
            association_data = association.to_csv_data( options )
          end

          if siblings.empty?
            siblings.push( *association_data )
          else
            temp = []
            association_data.each do |assoc_csv|
              siblings.each do |sibling|
                temp.push( sibling + assoc_csv )
              end
            end
            siblings = temp            
          end
        end
        siblings
      else
        []
      end
    end
    
    public
    
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
    
    def to_csv( options={} )
      FasterCSV.generate do |csv|
        headers = self.class.to_csv_headers( options )
        csv << headers if headers
        to_csv_data( options ).each{ |data| csv << data }
      end
    end
    
  end

  module ArrayInstanceMethods
    class NoRecordsError < StandardError ; end

    private
    
    def to_csv_headers( options )
      first.to_csv_headers( options )
    end
    
    
    public

    def to_csv_data( options={} )
      inject( [] ) do |arr,model_instance|
        arr.push( *model_instance.to_csv_data( options ) )
      end
    end
    
   end

end
