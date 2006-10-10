dir = File.dirname( __FILE__ )
ar_base_path = File.join( dir, 'lib', 'active_record_base' )
db_adapters_path = File.join( dir, 'lib', 'adapters' )

require File.join( ar_base_path, 'import' )
require File.join( ar_base_path, 'finders' )
#require File.join( ar_base_path, 'temporary_table' )

require File.join( db_adapters_path, 'abstract_adapter' )
require File.join( db_adapters_path, 'mysql_adapter' )



