begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

dir = File.dirname( __FILE__ )
require File.join( dir, 'lib', 'extensions' )

require File.join( dir, 'lib', 'fulltext' )
require File.join( dir, 'lib', 'fulltext', 'mysql' )

db_adapters_path = File.join( dir, 'lib', 'adapters' )

require File.join( dir, 'lib', 'import' )
require File.join( dir, 'lib', 'import', 'mysql' )
require File.join( dir, 'lib', 'import', 'postgresql' )

require File.join( dir, 'lib', 'finders' )

require File.join( db_adapters_path, 'abstract_adapter' )
require File.join( db_adapters_path,'mysql_adapter' )

