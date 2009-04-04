#insert select functionality is dependent on finder options
require 'ar-extensions/finder_options/mysql'

ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  include ActiveRecord::Extensions::Union::UnionSupport
end
