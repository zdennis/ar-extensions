
#Extend this module on ActiveRecord to access global functions
module ActiveRecord
  module Extensions
    module SqlGeneration#:nodoc:

      protected

      def post_sql_statements(options)#:nodoc:
        connection.post_sql_statements(quoted_table_name, options).join(' ')
      end

      def pre_sql_statements(options)#:nodoc:
        connection.pre_sql_statements({:command => 'SELECT'}.merge(options)).join(' ').strip + " "
      end

      def construct_ar_extension_sql(options={}, valid_options = [], &block)#:nodoc:
        options.assert_valid_keys(valid_options)if valid_options.any?

        sql = pre_sql_statements(options)
        yield sql, options
        sql << post_sql_statements(options)
        sql
      end
    end
  end
end
