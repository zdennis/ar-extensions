require 'forwardable'

module ActiveRecord::Extensions
  
  Result = Struct.new( :sql, :value )
  
  class Registry
    
    def []( arg )
      @registry[ arg ]
    end
    
    def registers?( arg )
      self[ arg ] ? true : false
    end

    def []=(a,b)
      @registry[a] = b
    end
    alias :register :[]=
      
    def initialize
      @registry = {}
    end

    def process( field, value, caller )
      current_adapter = caller.connection.adapter_name.downcase
      @registry.each_pair do |extension,options|
        adapters = options[:adapters]
        adapters.map!{ |e| e.to_s } unless adapters == :all
        next if options[:adapters] != :all and adapters.grep( /#{current_adapter}/ ).empty?
        if result=extension.process( field, value, caller )
          return result
        end
      end
      nil
    end
      
  end
  
  class << self
    extend Forwardable
    
    def register( extension, options )
      @registry ||= Registry.new
      @registry.register( extension, options )
    end
     
    def_delegator :@registry, :process, :process
  end
  
  
  module Abstract
    def Abstract.method(name, *args)
      code = "def #{name}(#{args.join(',')}) raise \"\#{self.class}\##{name} is abstract. Definition is a subclass responsibility.\" end"
      self.module_eval(code)
    end
  end

  
  class AbstractExtension
    include Abstract
    Abstract.method( :process, :key, :val, :caller )
  end

  
  class ArrayExt < AbstractExtension
    
    NOT_EQUAL_RGX = /(.+)_(ne|not|not_in)/
    
    def self.process( key, val, caller )
      if val.is_a?( Array )
        match_data = key.to_s.match( NOT_EQUAL_RGX )
        key = match_data.captures[0] if match_data
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )} " +
          (match_data ? 'NOT ' : '') + "IN( ? )"
        return Result.new( str, val )
      end
      nil
    end
    
  end
  register ArrayExt, :adapters=>:all
  
  # ActiveRecord::Extension to translate Hash keys which end in
  # +_lt+, +_lte+, +_gt+, or +_gte+ with the approriate <, <=, >,
  # or >= symbols.
  # * +_lt+ - denotes less than
  # * +_gt+ - denotes greater than
  # * +_lte+ - denotes less than or equal to
  # * +_gte+ - denotes greater than or equal to
  #
  # == Examples
  #  Model.find :all, :conditions=>{ 'number_gt'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_lt'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_gte'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_lte'=>100 }
  class Comparison < AbstractExtension
 
    SUFFIX_MAP = { 'eq'=>'=', 'lt'=>'<', 'lte'=>'<=', 'gt'=>'>', 'gte'=>'>=', 'ne'=>'!=', 'not'=>'!=' }
    
    def self.process( key, val, caller )
      process_without_suffix( key, val, caller ) || process_with_suffix( key, val, caller )
    end
    
    def self.process_without_suffix( key, val, caller )
      return nil unless caller.columns_hash.has_key?( key )
      if val.nil?
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )} IS NULL"
      else
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )}=" +
          "#{caller.connection.quote( val, caller.columns_hash[ key ] )} "
      end
      Result.new( str, nil )
    end

    def self.process_with_suffix( key, val, caller )
      return nil unless val.is_a?( String ) or val.is_a?( Numeric )
      SUFFIX_MAP.each_pair do |k,v|
        match_data = key.to_s.match( /(.+)_#{k}$/ )
        if match_data
          fieldname = match_data.captures[0]
          str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} " +
            "#{v} #{caller.connection.quote( val, caller.columns_hash[ fieldname ] )} "
          return Result.new( str, nil )
        end
      end
      nil
    end
    
  end
  register Comparison, :adapters=>:all

  
  # ActiveRecord::Extension to translate Hash keys which end in
  # +_like+ or +_contains+ with the approriate LIKE keyword
  # used in SQL. 
  #
  # == Examples
  #  # the below two examples are equivalent
  #  Model.find :all, :conditions=>{ 'name_like' => 'John' }
  #  Model.find :all, :conditions=>{ 'name_contains' => 'John' }
  class Like < AbstractExtension
    LIKE_RGX = /(.+)_(like|contains)$/
    STARTS_WITH_RGX = /(.+)_starts_with$/
    ENDS_WITH_RGX =  /(.+)_ends_with$/
    
    def self.process( key, val, caller )
      if match_data=key.to_s.match( LIKE_RGX )
        fieldname = match_data.captures[0]
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} LIKE ?"
        return Result.new( str, "%#{val}%" )
      elsif match_data=key.to_s.match( STARTS_WITH_RGX )
        fieldname = match_data.captures[0]
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} LIKE ?"
        return Result.new( str, "#{val}%" )
      elsif match_data=key.to_s.match( ENDS_WITH_RGX )
        fieldname = match_data.captures[0]
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} LIKE ?"
        return Result.new( str, "%#{val}" )
      end
      nil
    end
    
  end
  register Like, :adapters=>:all 

  
  class RangeExt < AbstractExtension
    NOT_IN_RGX = /(.+)_(ne|not|not_in)/
    
    def self.process( key, val, caller )
      if val.is_a?( Range )
        match_data = key.to_s.match( NOT_IN_RGX )
        key = match_data.captures[0] if match_data
        fieldname = caller.connection.quote_column_name( key )
        min = caller.connection.quote( val.first, caller.columns_hash[ key ] )
        max = caller.connection.quote( val.last, caller.columns_hash[ key ] )
        str = "#{caller.table_name}.#{fieldname} #{match_data ? 'NOT ' : '' } BETWEEN #{min} AND #{max}"
        return Result.new( str, nil )
      end
      nil      
    end
    
  end
  register RangeExt, :adapters=>:all  
  

  class RegexpMySQL < AbstractExtension
    
    NOT_EQUAL_RGX = /(.+)_(ne|not)/
    
    def self.process( key, val, caller )
      if val.is_a?( Regexp )
        match_data = key.to_s.match( NOT_EQUAL_RGX )
        key = match_data.captures[0] if match_data
        fieldname = caller.connection.quote_column_name( key )
        return Result.new( "#{caller.table_name}.#{fieldname} #{match_data ? 'NOT ':''} REGEXP ?", val )
      end
      nil
    end
    
  end
  register RegexpMySQL, :adapters=>[ :mysql ]


  # This doesn't support case insensitive matches. 
  class RegexpPostgreSQL < AbstractExtension
   
    NOT_EQUAL_RGX = /(.+)_(ne|not)/
    
    def self.process( key, val, caller )
      if val.is_a?( Regexp )
        match_data = key.to_s.match( NOT_EQUAL_RGX )
        key = match_data.captures[0] if match_data
        fieldname = caller.connection.quote_column_name( key )
        return Result.new( "#{caller.table_name}.#{fieldname} #{match_data ? '!~ ':'~'} ?", val )
      end
      nil
    end
    
  end
  register RegexpPostgreSQL, :adapters=>[ :postgresql ]

  
end



