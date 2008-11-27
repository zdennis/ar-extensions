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
      generate to_sql_options.merge(:max_bytes_per_statement => max_bytes_per_statement)
    end
    
    private

    def generate(options)
      max_bytes_per_statement = options[:max_bytes_per_statement]
      token_rgx_string = @template.mappings.keys.map{ |e| Regexp.escape(":#{e.to_s}") }.join("|")
      token_rgx = /#{token_rgx_string}/
      tokens = @template.to_s.scan(token_rgx)
      parts = @template.to_s.dup.split(token_rgx)
      
      index = tokens.index(":table")
      content = @template.mappings[:table].call options[:table]
      parts[index] << content

      index = tokens.index(":columns")
      content = @template.mappings[:columns].call options[:columns]
      parts[index] << content
      
      insert_values_at = parts[0..tokens.index(":values")].join.length
      statements = []
      value_sets = @template.mappings[:values].call options[:values]
      builder = ValueSetFragments.new(value_sets) do |t|
        t.max_bytes_per_statement = max_bytes_per_statement - parts.inject(0){ |sum, part| sum + part.length } 
      end
      builder.each_fragment do |fragment|
        statement = parts.join
        statement.insert insert_values_at, fragment
        statements << statement
      end
      
      statements
    end

    def to_sql_options
      { :table => table, :columns => columns, :values => values }
    end
  end
end