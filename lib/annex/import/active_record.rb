class ActiveRecord::Base
  
  def self.generate_sql(identifier, &blk)
    sql_generator = ContinuousThinking::SQL::Generator.for(identifier)
    yield sql_generator
    sql_generator.to_sql_statement
  end
  
  def self.import(*args)
    instances, invalid_instances = nil, []
    options = { :validate => true }
    
    if args.size == 1
      columns = column_names.dup
      instances = args.first
      values = instances.map{ |model| columns.map{ |column| model.attributes[column] } }
    elsif args.size == 2 && args.last.is_a?(Array)
      columns, values = args
    elsif args.size == 2 && args.last.is_a?(Hash)
      options.merge! args.pop
      columns = column_names.dup
      instances = args.first
      values = instances.map{ |model| columns.map{ |column| model.attributes[column] } }
    elsif args.size == 3 && args.last.is_a?(Hash)
      options.merge! args.pop
      columns, values = args
    end
    
    sql_statement = generate_sql :insert_into do |sql|
      sql.table = quoted_table_name
      sql.columns = columns.map{ |name| connection.quote_column_name(name) }
      sql.values = values.map{ |rows| rows.map{ |row| 
        connection.quote(row, columns_hash[columns[values.index(rows)]]) } }
      sql.options = options
    end

    if options[:validate]
      if instances.nil?
        instances = []
        values.each do |rows|
          attrs = {}
          rows.each_with_index do |value, index|
            attrs[columns[index]] = value
          end
          instances << new(attrs)
        end
      end
      invalid_instances = instances.select{ |instance| !instance.valid? }
    end

    if invalid_instances.any?
      return ContinuousThinking::SQL::Result.new(:num_inserts => 0, :failed_instances => invalid_instances)
    end      
    
    connection.execute sql_statement
    ContinuousThinking::SQL::Result.new(:num_inserts => values.size, :failed_instances => [])
  end
  
end