begin ; require 'rubygems' rescue LoadError; end
require 'active_record' # ActiveRecord loads the Benchmark library automatically
require 'active_record/version'

require File.expand_path(File.join( File.dirname( __FILE__ ), '..', 'init.rb' ))

MYSQL_ADAPTER_CLASS = if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
  ActiveRecord::ConnectionAdapters::MysqlAdapter
elsif defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
  ActiveRecord::ConnectionAdapters::Mysql2Adapter
else
  raise "ar-extensions: Missing or unknown ActiveRecord::ConnectionAdapter"
end