#insert select functionality is dependent on finder options and import
require 'ar-extensions/finder_options/mysql'
require 'ar-extensions/import/mysql'

ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  include ActiveRecord::Extensions::InsertSelectSupport
end