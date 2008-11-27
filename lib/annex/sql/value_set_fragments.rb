module ContinuousThinking::SQL
  class ValueSetFragments
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
end