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
      when Array
        includes.map do |association| 
          clazz = get_class.call( association )
          clazz.to_csv_headers( :headers=>true, :naming=>":model[:header]" )
        end
      when Hash
        includes.inject( [] ) do |arr,(association,options)|
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

      headers.map!{ |header| options[:naming].gsub( /:header/, header ).gsub( /:model/, self.name.downcase ) }

      if options[:include] and false
        included_headers = 
          case options[:include]
          when Array
            arr = options[:include].map{ |association| Object.const_get( self.reflections[ association.to_sym ].class_name ).to_csv_headers( :headers=>true ) }
            headers.push( *arr.flatten )
          when Hash
          end
      end
      headers
    end

  end

  
  module InstanceMethods

    private
    
    def to_csv_data_for_included_associations( includes )
      case includes
      when Array
        includes.map { |association| self.send( association ).to_csv_data }
      when Hash
        includes.inject( [] ) do |arr,(association,options)|
          begin
            arr << self.send( association ).to_csv_data( options )
          rescue NoMethodError
            arr << Object.const_get( Inflector.classify( association ) ).columns.map{ |e| nil.to_s }
          end
        end
      else
        []
      end
    end
    
    public
    
    def to_csv_data( options={} )
      fields = self.class.to_csv_fields( options ).fields
      data = fields.inject( [] ) { |arr,field| arr << attributes[field].to_s }
      data.push( *to_csv_data_for_included_associations( options[:include ] ).flatten )
      data
    end
    
    def to_csv( options={} )
      FasterCSV.generate do |csv|
        headers = self.class.to_csv_headers( options )
        csv << headers if headers
        csv << to_csv_data( options )
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

    def to_csv( options={} )
      raise NoRecordsError.new if self.size == 0
#      fields = to_csv_fields_for_options( options )
      csv_info = to_csv_info( options )
     
      included_fields = nil
      if options.has_key?( :include )
        included_fields = self.first.to_csv_fields_included_from_associations( options[ :include ] ) 
      end

      csv = FasterCSV.generate do |csv|
         
        unless options[:headers] == false
          headers = []
          headers.push( *fields )

          included_fields.each do |obj|
            headers.push( *obj.headers )
          end unless included_fields.nil?


          csv << headers
        end

        data = []
        each do |e|
          fields.each{ |field| data << e.attributes[ field ].to_s }
          csv << data
          data.clear
        end
      end
      csv
    end
    
    def to_csv_file( filepath, *args )
      mode, options = nil, {}

      if args.empty?
        mode = 'w'
      elsif args.first.is_a?( String )
        mode = args.first
      elsif args.first.is_a?( Hash )
        mode, options = 'w', args.first
      elsif args.size == 2
        mode, options = args
      end

      raise ArgumentError.new( "Unknown arguments: #{args}" ) if mode.nil?

      csv = to_csv( options )
      File.open( filepath, mode ){ |io| io.write( csv ) }
      csv
    end
    
  end

end
