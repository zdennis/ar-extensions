require 'faster_csv'

module ActiveRecord::Extensions::FindToCSV
  def self.included( cl )
    cl.instance_eval "
      alias :_original_find :find
      def find( *args )
        results = _original_find( *args )
        results.extend( ArrayExtension ) if results.is_a?( Array )
        results
      end
    "
  end

  module ArrayExtension
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
