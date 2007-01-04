require 'faster_csv'
require 'ostruct'

module ActiveRecord::Extensions::FindToCSV
  ALIAS_FOR_FIND = :_original_find_before_arext

  def self.included( cl )
    if not cl.ancestors.include?( self::ClassMethods )
      cl.instance_eval "alias #{ALIAS_FOR_FIND} :find"
      cl.extend( ClassMethods )
      cl.send( :include, InstanceMethods )
    end
  end

  module ClassMethods

    private
    
    def to_csv_headers_for_array( headers )
      wanted_headers = headers.map{ |e| e.to_s }
      columns = self.columns.select{ |c| wanted_headers.include?( c.name ) }
      columns.map{ |c| c.name }
    end

    def to_csv_headers_for_hash( headers )
      headers.values
    end

    def to_csv_headers_for_unknown_headers_type( headers )
      case headers
      when true
        self.columns.map{ |column| column.name }
      when Array
        to_csv_headers_for_array( headers )
      when Hash
        to_csv_headers_for_hash( headers )
      end
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

# supports -->  options = { :headers=>true, :naming=>":model[:header]" }.merge( options )
    def to_csv_headers( options={} )
      options = { :headers=>true, :naming=>":header" }.merge( options )
      return nil if options[:headers] == false
      
      headers = to_csv_headers_for_unknown_headers_type( options[ :headers ] )
      headers.push( *to_csv_headers_for_included_associations( options[ :include ] ).flatten )

      if options[:only]
        specified_fields = options[:only].map{ |e| e.to_s }
        headers.delete_if{ |header| not specified_fields.include?( header ) }
      elsif options[:except]
        excluded_fields = options[:except].map{ |e| e.to_s }
        headers.delete_if{ |header| excluded_fields.include?( header ) }
      end

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
    def to_csv_fields_included_from_associations( includes )
      if includes.is_a?( Array )
        to_csv_fields_included_from_associations_as_array( includes.map{ |e| e.to_sym } )
      elsif includes.is_a?( Hash )
        to_csv_fields_included_from_associations_as_hash( includes )
      else
        raise ArgumentError.new( "Expected Array or Hash!" )
      end
    end

    def to_csv_fields_included_from_associations_as_array( includes )
      includes.inject( [] ) do |arr,association|
        association_class = Object.const_get( reflections[ association ].class_name )
        fields = association_class.columns_hash.keys
        headers = fields.map{ |f| "#{association}[#{f}]" }
        arr << OpenStruct.new( :fields => fields, :headers=> headers )
      end
    end

    def to_csv_fields_included_from_associations_as_hash( includes )
      includes.inject( [] ) do |arr,(association,options)|
        association_class = Object.const_get( reflections[ association ].class_name )
        fields = to_csv_fields_for_options( options )
        headers = fields.map{ |f| "#{association}[#{f}]" }
        arr << OpenStruct.new( :fields => fields, :headers => headers )
      end
    end

    public

    def to_csv_fields_for_options( options )
      fields = attributes.keys.inject( [] ){ |arr,k| arr << k }
      if options.has_key?( :only )
        fields = options[:only].map{ |fieldname| fieldname.to_s }
      elsif options.has_key?( :except )
        fields = fields - options[:except].map{ |fieldname| fieldname.to_s }
      end     
      fields
    end

    def to_csv_headers( options )
      self.class.to_csv_headers( options )
    end

  end


  module ArrayInstanceMethods
    class NoRecordsError < StandardError ; end

    private
    
#    def to_csv_fields_for_options( options )
#      first.to_csv_fields_for_options( options )
#    end

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
#puts "", included_fields.inspect, ""
          included_fields.each do |obj|
            headers.push( *obj.headers )
          end unless included_fields.nil?
#puts headers.inspect

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
