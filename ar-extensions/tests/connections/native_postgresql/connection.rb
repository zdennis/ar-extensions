puts "Using native PostgreSQL"

ActiveRecord::Base.logger = Logger.new("debug.log")

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class PostgreSQLAdapter # :nodoc:
      def default_sequence_name(table_name, pk = nil)
        default_pk, default_seq = pk_and_sequence_for(table_name)
        default_seq || "#{table_name}_#{pk || default_pk || "id"}_seq"
      end 
    end
  end
end

ActiveRecord::Base.configurations["test"] = {
  :adapter  => "postgresql",
  :username => "postgres",
  :password => "password",
  :host => 'localhost',
  :database => db1,
  :min_messages => "warning"
}

ActiveRecord::Base.establish_connection("test")



