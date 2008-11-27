module ContinuousThinking::SQL
  class Generator
    attr_accessor :columns, :table, :values
    
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
    
    def to_sql_statement
      @template.interpolate to_sql_options
    end
    
    private

    def to_sql_options
      { :table => table, :columns => columns, :values => values }
    end
  end
end