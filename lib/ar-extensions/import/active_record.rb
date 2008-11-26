module ContinuousThinking
  class SQLGenerator
    attr_accessor :columns, :values, :table
    
    def initialize(statement, options={}, &blk)
      @statement = statement
      @table = options[:table]
    end
    
    def full_sql_statement
      generate
    end
    
    private
    
    def generate
      values = self.values.map{ |row| "(#{row.join(',')})" }
      "INSERT INTO #{table} (#{columns.join(',')}) VALUES #{values.join(',')}"
    end
  end
end 

class ActiveRecord::Base
  
  def self.generate_sql(statement, options={}, &blk)
    generator = ContinuousThinking::SQLGenerator.new(statement, options)
    yield generator
    generator.full_sql_statement
  end
  
  def self.import(*args)
    if args.size == 2 && args.last.is_a?(Array)
      columns, values = args
      sql = generate_sql :insert_into, :table => quoted_table_name do |_sql|
        _sql.columns = columns.map{ |name| connection.quote_column_name(name) }
        _sql.values = values.map{ |rows| rows.map{ |row| connection.quote(row, values.index(rows)) } }
      end
    end
    
    connection.execute sql
  end
  
end