ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  include ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter
end
