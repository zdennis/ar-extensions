module ContinuousThinking::ActiveRecord
  class DataImporter
    tproc = lambda { ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now }
    TIMESTAMP_COLUMNS = {
      :create => { "created_on" => tproc ,
                   "created_at" => tproc },
      :update => { "updated_on" => tproc ,
                   "updated_at" => tproc }
    }

    def generate_sql(identifier, &blk)
      sql_generator = ContinuousThinking::SQL::Generator.for(identifier)
      yield sql_generator
      sql_generator.to_sql_statements
    end
  
    def import(*args)
      process_args(*args)
      perform_validation if perform_validation?
    
      if using_model_instances?
        if @instances.empty?
          return ContinuousThinking::SQL::Result.new(:num_inserts => 0, :failed_instances => @invalid_instances)
        else
          build_values_from_model_instances
        end
      end
    
      add_timestamps if using_timestamps?
        
      connection = @model.connection
      sql_statements = generate_sql :insert_into do |sql|
        sql.table = @model.quoted_table_name
        sql.columns = @columns.map{ |name| connection.quote_column_name(name) }
        sql.values = @values.map{ |rows| rows.map{ |field| connection.quote(field, @model.columns_hash[@columns[rows.index(field)]]) } }
        sql.options = @options
      end
      sql_statements.each { |statement| connection.execute statement }
      ContinuousThinking::SQL::Result.new(:num_inserts => @values.size, :failed_instances => @invalid_instances)
    end
  
    private
  
    def add_timestamps
      TIMESTAMP_COLUMNS[:create].each_pair do |timestamp_column, timestamp_proc|
        if @model.column_names.include?(timestamp_column) && !@columns.include?(timestamp_column.to_sym)
          timestamp = timestamp_proc.call
          @columns << timestamp_column
          @values.each { |row| row << timestamp }
        end
      end

      TIMESTAMP_COLUMNS[:update].each_pair do |timestamp_column, timestamp_proc|
        if @model.column_names.include?(timestamp_column) && !@columns.include?(timestamp_column.to_sym)
          timestamp = timestamp_proc.call
          @columns << timestamp_column
          @values.each { |row| row << timestamp }
        end
      end
    end
  
    def build_values_from_model_instances
      @values = @instances.map{ |model_instance| @columns.map{ |column| model_instance.attributes[column.to_s] } }
    end
  
    def perform_validation?
      @options[:validate]
    end
  
    def perform_validation
      if @instances.nil?
        @instances = []
        @values.each do |rows|
          attrs = {}
          rows.each_with_index do |value, index|
            attrs[@columns[index]] = value
          end
          @instances << @model.new(attrs)
        end
      end
      @invalid_instances = @instances.select{ |instance| !instance.valid? }
      @instances -= @invalid_instances
    end
  
    def process_args(*args)
      instances = nil
      options = args.pop
      @model = options[:model]
    
      if args.size == 1
        columns = @model.column_names.dup
        instances = args.first
      elsif args.size == 2 && args.last.is_a?(Array)
        if args.last.first.kind_of?(ActiveRecord::Base)
          columns, instances = args
        else
          columns, values = args
        end
      end
    
      @columns = columns.map{ |c| c.to_sym }
      @values = values
      @instances = instances
      @invalid_instances = []
      @options = options
    end
  
    def using_model_instances?
      @instances
    end
  
    def using_timestamps?
      @options[:timestamps]
    end
  end
end


class ActiveRecord::Base
  def self.import(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = {:validate => true, :timestamps => true, :model => self}.merge(options)
    args << options
    importer = ContinuousThinking::ActiveRecord::DataImporter.new
    importer.import *args
  end
end