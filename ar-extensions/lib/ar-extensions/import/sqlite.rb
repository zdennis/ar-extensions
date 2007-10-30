module ActiveRecord::Extensions::ConnectionAdapters::SQLiteAdapter # :nodoc:
  include ActiveRecord::Extensions::Import::ImportSupport  
  
  def post_sql_statements( table_name, options )
    []
  end

  def insert_many( sql, values, *args ) # :nodoc:
    sql2insert = []
    values.each do |value|
      sql2insert << "#{sql} #{value};"
    end
    
    raw_connection.transaction { |db| db.execute_batch(sql2insert.join("\n")) }
    number_of_rows_inserted = sql2insert.size
  end

end

ActiveRecord::ConnectionAdapters::SQLiteAdapter.class_eval do
  include ActiveRecord::Extensions::ConnectionAdapters::SQLiteAdapter
end
