require 'faster_csv'

=begin
TODO - support to_csv( filename, options )
OPTIONS TO SUPPORT:
 :headers 
 :exclude_columns
 :include_columns
=end

module ActiveRecord::Extensions::FindToCSV
  ALIAS_FOR_FIND = :_original_find_before_arext

  def self.included( cl )
    cl.instance_eval "alias #{ALIAS_FOR_FIND} :find"
    cl.extend( ClassMethods )
  end

  module ClassMethods
    def find( *args )
      results = self.send( ALIAS_FOR_FIND, *args )
      results.extend( InstanceMethods ) if results.is_a?( Array )
      results
    end
  end

  module InstanceMethods
    def to_csv( filename )
      csv = FasterCSV.generate do |csv|
        csv << self.first.attributes.sort.map{ |arr| arr.first }
         self.each do |row|
          csv << self.first.attributes.sort.map{ |arr| arr.last }
         end
      end
      File.open( filename, "w" ){ |io| io.puts csv }
    end
  end
end
