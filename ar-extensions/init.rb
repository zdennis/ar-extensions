begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

dir = File.dirname( __FILE__ )
require File.join( dir, 'lib', 'extensions' )
require File.join( dir, 'lib', 'fulltext' )


ar_base_path = File.join( dir, 'lib', 'active_record_base' )
db_adapters_path = File.join( dir, 'lib', 'adapters' )

require File.join( ar_base_path, 'import' )
require File.join( ar_base_path, 'finders' )

require File.join( db_adapters_path, 'abstract_adapter' )
require File.join( db_adapters_path, 'mysql_adapter' )

