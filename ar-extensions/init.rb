require 'ostruct'
begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

dir = File.dirname( __FILE__ )
require File.join( dir, 'lib/ar-extensions', 'version' )
require File.join( dir, 'lib/ar-extensions', 'extensions' )

begin 
  require 'faster_csv' 
  require File.join( dir, 'lib/ar-extensions', 'csv' )
rescue LoadError
  STDERR.puts "FasterCSV is not installed. CSV functionality will not be included."
end

require File.join( dir, 'lib/ar-extensions', 'foreign_keys' )
require File.join( dir, 'lib/ar-extensions', 'fulltext' )
require File.join( dir, 'lib/ar-extensions', 'fulltext', 'mysql' )

db_adapters_path = File.join( dir, 'lib/ar-extensions', 'adapters' )

require File.join( dir, 'lib/ar-extensions', 'import' )
require File.join( dir, 'lib/ar-extensions', 'import', 'mysql' )
require File.join( dir, 'lib/ar-extensions', 'import', 'postgresql' )

require File.join( dir, 'lib/ar-extensions', 'finders' )

require File.join( db_adapters_path, 'abstract_adapter' )
require File.join( db_adapters_path,'mysql_adapter' )

