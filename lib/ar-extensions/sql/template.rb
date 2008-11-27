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
      rgx = @mappings.keys.map{ |e| Regexp.escape(":#{e.to_s}") }.join("|")
      @body.gsub /#{rgx}/ do |key|
        key = key[1..-1].to_sym
        @mappings[key].call options[key]
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