begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

dir = File.dirname( __FILE__ )
require File.join( dir, 'lib/ar-extensions', 'extensions' )

require File.join( dir, 'lib/ar-extensions', 'csv' )

require File.join( dir, 'lib/ar-extensions', 'fulltext' )
require File.join( dir, 'lib/ar-extensions', 'fulltext', 'mysql' )

db_adapters_path = File.join( dir, 'lib/ar-extensions', 'adapters' )

require File.join( dir, 'lib/ar-extensions', 'import' )
require File.join( dir, 'lib/ar-extensions', 'import', 'mysql' )
require File.join( dir, 'lib/ar-extensions', 'import', 'postgresql' )

require File.join( dir, 'lib/ar-extensions', 'finders' )

require File.join( db_adapters_path, 'abstract_adapter' )
require File.join( db_adapters_path,'mysql_adapter' )

