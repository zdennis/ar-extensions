module ActiveRecord::Extensions::ConnectionAdapters::SQLiteAdapter # :nodoc:
  include ActiveRecord::Extensions::Import::ImportSupport  
  
  def multiple_value_sets_insert_sql( table_name, column_names, options ) # :nodoc:    
    "INSERT #{options[:ignore] ? 'IGNORE ':''}INTO #{table_name} (#{column_names.join(',')}) VALUES "
  end  
  
  # Returns SQL the VALUES for an INSERT statement given the passed in +columns+ 
  # and +array_of_attributes+.
  def values_sql_for_column_names_and_attributes( columns, array_of_attributes )   # :nodoc:
    values = []
    array_of_attributes.each do |arr|
      my_values = []
      arr.each_with_index do |val,j|
        my_values << quote( val, columns[j] )
      end
      values << my_values
    end   
    values_arr = values.map{ |arr| '(' + arr.join( ',' ) + ')' }
  end
  
  def post_sql_statements( table_name, options )
    []
  end

  def insert_many( sql, values, *args ) # :nodoc:
    sql2insert = []
    values.each do |value|
      sql2insert << "#{sql} #{value};"
    end
    
    raw_connection.execute_batch(sql2insert.join("\n"))
    number_of_rows_inserted = sql2insert.size
  end

end

ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
  include ActiveRecord::Extensions::ConnectionAdapters::SQLiteAdapter
end
