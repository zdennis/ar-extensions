module ContinuousThinking::SQL
  class Template
    attr_reader :mappings
    
    def initialize(identifier, &blk)
      @identifier = identifier
      @mappings = {}
      instance_eval &blk
    end
    
    def body(body)
      @body = body
    end
    
    def mapping(definition)
      @mappings.merge! definition
    end
    
    def matches?(identifier)
      @identifier == identifier
    end
    
    def to_s
      @body
    end
    
  end
end
