ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
  include ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter
end
