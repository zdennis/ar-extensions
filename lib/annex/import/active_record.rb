class ActiveRecord::Base
  
  def self.generate_sql(identifier, &blk)
    sql_generator = ContinuousThinking::SQL::Generator.for(identifier)
    yield sql_generator
    sql_generator.to_sql_statement
  end
  
  def self.import(*args)
    if args.size == 2 && args.last.is_a?(Array)
      columns, values = args
      sql_statement = generate_sql :insert_into do |sql|
        sql.table = quoted_table_name
        sql.columns = columns.map{ |name| connection.quote_column_name(name) }
        sql.values = values.map{ |rows| rows.map{ |row| connection.quote(row, values.index(rows)) } }
      end
    elsif args.size == 3 && args.last.is_a?(Hash)
      options = args.pop
      columns, values = args
      sql_statement = generate_sql :insert_into do |sql|
        sql.table = quoted_table_name
        sql.columns = columns.map{ |name| connection.quote_column_name(name) }
        sql.values = values.map{ |rows| rows.map{ |row| connection.quote(row, values.index(rows)) } }
        sql.options = options
      end
    end
    
    connection.execute sql_statement
  end
  
end