MYSQL_ADAPTER_CLASS.class_eval do
  include ActiveRecord::Extensions::Delete::DeleteSupport
end
