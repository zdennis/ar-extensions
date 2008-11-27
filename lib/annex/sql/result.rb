module ContinuousThinking::SQL
  class Result
    def initialize(options)
      @options = options
    end
    
    def method_missing(name, *args)
      return @options[name] if @options.has_key?(name)
      super
    end
  end
end
