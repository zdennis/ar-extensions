module ActiveRecord::ConnectionAdapters::Quoting

  alias :quote_orig :quote
  def quote( value, column=nil )
    if value.is_a?( Regexp )
      "'#{value.inspect[1...-1]}'"
    else
      quote_orig( value, column )
    end
  end
end


class ActiveRecord::Base

  SANITIZE_MAP = { 
    'lt'=>'<', 
    'gt'=>'>', 
    'lte'=>'<=', 
    'gte'=>'>=' }.freeze

 private

  class << self
    
    alias :attribute_condition_orig :attribute_condition   
    def attribute_condition( argument, negate=false )
      case argument
        when Array
          negate ? "NOT IN( ? )" : attribute_condition_orig( argument )
        when Range 
          negate ? "NOT BETWEEN ? AND ?" : "BETWEEN ? AND ?"
        # TODO add regexp support for other databases besides MySQL
        when Regexp 
          negate ? "NOT REGEXP ?" : "REGEXP ?"
        when String, Numeric
          negate ? "!= ?" : attribute_condition_orig( argument )
      else
        attribute_condition_orig( argument )
      end
    end
    
    alias :sanitize_sql_orig :sanitize_sql
    def sanitize_sql( arg )
      arg = sanitize_sql_from_hash( arg ) if arg.is_a?( Hash )
      sanitize_sql_orig( arg )
    end
    
    # TODO Refactor sanitize_sql_from_hash and break up into smaller more manageable methods
    def sanitize_sql_from_hash( hsh ) # :nodoc:
      # build a conditions Array that find methods typically expect
      arr = hsh.inject( [ Array.new ] ) do |arr,(key,val)|
        found = SANITIZE_MAP.inject( false ){ |found,(k,v)|
          column = columns_hash[ $1 ]
          if key.to_s =~ /(.+)_(#{k.to_s})$/
            arr.first << "#{$1} #{v} #{connection.quote(val,column)} "
            break true
          elsif key.to_s =~ /(.+)_(ne)$/
            arr.first << "#{$1} #{attribute_condition( val, true )} "
            break true
          elsif key.to_s =~ /(.+)_like$/
            arr.first << "#{$1} LIKE ?"
            val = "%#{val}%"
            break true
          elsif key.to_s =~ /(.+)_starts_with$/
            arr.first << "#{$1} LIKE ?"
            val = "#{val}%"
            break true
          elsif key.to_s =~ /(.+)_ends_with$/
            arr.first << "#{$1} LIKE ?"
            val = "%#{val}"
            break true
          end
        }       

        if not found
          arr.first << key.to_s + " #{attribute_condition( val )} "
        end

        if val.is_a?( Range )
          arr.push( *[val.first,val.last] )   
        else
          arr << val
        end
        arr
      end
      arr[0] = arr.first.join( ' AND ' )
      arr
    end
    
  end
  
end
