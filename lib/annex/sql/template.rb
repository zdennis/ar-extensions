module ContinuousThinking::SQL
  class Template
    def initialize(identifier, &blk)
      @identifier = identifier
      @mappings = {}
      instance_eval &blk
    end
    
    def body(body)
      @body = body
    end

    def interpolate(options)
      max_bytes_per_statement = options[:max_bytes_per_statement]
      token_rgx_string = @mappings.keys.map{ |e| Regexp.escape(":#{e.to_s}") }.join("|")
      token_rgx = /#{token_rgx_string}/
      tokens = @body.scan(token_rgx)
      parts = @body.dup.split(token_rgx)
      
      index = tokens.index(":table")
      content = @mappings[:table].call options[:table]
      parts[index] << content

      index = tokens.index(":columns")
      content = @mappings[:columns].call options[:columns]
      parts[index] << content
      
      insert_values_at = parts[0..tokens.index(":values")].join.length
      statements = []
      value_sets = @mappings[:values].call options[:values]
      builder = FragmentBuilder.new(value_sets) do |t|
        t.max_bytes_per_statement = max_bytes_per_statement - parts.inject(0){ |sum, part| sum + part.length } 
      end
      builder.each_fragment do |fragment|
        statement = parts.join
        statement.insert insert_values_at, fragment
        statements << statement
      end
      
      statements
    end
    
    class FragmentBuilder
      attr_accessor :max_bytes_per_statement
      
      def initialize(value_sets, &blk)
        @value_sets = value_sets
        yield self if block_given?
      end
      
      def each_fragment(&blk)
        fragments.each &blk
      end

      protected
      
      def fragments
        start_of_fragment = true
        fragments = [""]
        @value_sets.each do |value_set|
          delimiter = start_of_fragment ? "" : ","
          possible_fragment_length = fragments.last.length + value_set.length + delimiter.length
          if possible_fragment_length > max_bytes_per_statement
            delimiter = ""
            fragments << ""
          end
          fragments.last << delimiter + value_set
          start_of_fragment = false
        end
        fragments
      end
    end

    def mapping(definition)
      @mappings.merge! definition
    end
    
    def matches?(identifier)
      @identifier == identifier
    end
    
  end
end
