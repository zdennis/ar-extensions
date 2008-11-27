module ContinuousThinking::SQL
  class Generator
    Infinity = 1.0/0

    attr_accessor :columns, :max_bytes_per_statement, :options, :table, :values
    
    def self.templates
      ContinuousThinking::SQL.templates
    end
    
    def self.for(identifier)
      template = templates.detect{ |template| template.matches?(identifier) }
      generator = new template
    end

    def initialize(template)
      @template = template
    end
    
    def max_bytes_per_statement
      @max_bytes_per_statement || Infinity
    end
    
    def to_sql_statements
      @template.interpolate to_sql_options.merge(:max_bytes_per_statement => max_bytes_per_statement)
    end
    
    private

    def to_sql_options
      { :table => table, :columns => columns, :values => values }
    end
  end
end