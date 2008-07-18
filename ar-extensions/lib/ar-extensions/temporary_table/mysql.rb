ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  include ActiveRecord::Extensions::TemporaryTableSupport 
end
