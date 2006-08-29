require 'boot'

# Parse the options passed in via the command line
options = BenchmarkOptionParser.parse( ARGV )

# The lib directory that houses the library files we need to benchmark
LIB_DIR = File.expand_path(
File.join( File.dirname( __FILE__ ), '..', 'lib' ) )

# The support directory where we use to load our connections and models for the 
# benchmarks.
SUPPORT_DIR = File.expand_path( 
  File.join( File.dirname( __FILE__ ), '..', 'tests' ) )

# Load our library files
Dir[ File.join( LIB_DIR, '**/*.rb' ) ].each{ |f| require f }

# Load the database adapter
db_adapter = options.adapter
require File.join( SUPPORT_DIR, 'connections', "native_#{db_adapter}", 'connection' )

# Load all generic models
Dir[ File.join( SUPPORT_DIR, 'models/*.rb' ) ].each{ |f| require f }

# Load database adapter specific models
Dir[ File.join( SUPPORT_DIR, 'models', "#{db_adapter}/*.rb" ) ].each{|f| require f }

# Load databse specific benchmarks
require File.join( File.dirname( __FILE__ ), 'lib', "#{db_adapter}_benchmark" )

# TODO implement method/table-type selection
table_types = nil
if options.benchmark_all_types
  table_types = [ "all" ]
else
  table_types = options.table_types.keys
end
puts

letter = options.adapter[0].chr
clazz_str = letter.upcase + options.adapter[1..-1].downcase
clazz = Object.const_get( clazz_str + "Benchmark" )

benchmarks = []
options.number_of_objects.each do |num|
  benchmarks << (benchmark = clazz.new)
  benchmark.send( "benchmark", table_types, num )
end

options.outputs.each do |output|
  format = output.format.downcase
  require File.join( File.dirname( __FILE__ ), 'lib', "output_to_#{format}" )
  output_module = Object.const_get( "OutputTo#{format.upcase}" )
  benchmarks.each do |benchmark|
    output_module.output_results( output.filename, benchmark.results )
  end
end

puts
puts "Done with benchmark!"

