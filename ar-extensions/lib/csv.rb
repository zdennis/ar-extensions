require 'faster_csv'

module ActiveRecord::Extensions::FindToCSV
  ALIAS_FOR_FIND = :_original_find_before_arext

  def self.included( cl )
    if not cl.ancestors.include?( self::ClassMethods )
      cl.instance_eval "alias #{ALIAS_FOR_FIND} :find"
      cl.extend( ClassMethods )
    end
  end

  module ClassMethods
    def find( *args )
      results = self.send( ALIAS_FOR_FIND, *args )
      results.extend( InstanceMethods ) if results.is_a?( Array )
      results
    end
  end

  module InstanceMethods
    class NoRecordsError < StandardError ; end
 
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

    def to_csv( options={} )
      raise NoRecordsError.new if self.size == 0
      headers = options[:headers] || self.first.attributes.keys.inject( [] ){ |arr,k| arr<<k }
      headers = headers.map{ |e| e.to_s }

      csv = FasterCSV.generate do |csv|
        csv << headers
        each do |e|
          csv << headers.inject( [] ){ |arr,hdr| arr << e.attributes[ hdr ].to_s }
        end
      end
      csv
    end
  end

end
