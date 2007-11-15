module ActiveRecord::ConnectionAdapters::Quoting

  alias :quote_before_arext :quote
  def quote( value, column=nil ) # :nodoc:
    if value.is_a?( Regexp )
      "'#{value.inspect[1...-1]}'"
    else
      quote_before_arext( value, column )
    end
  end
end


class ActiveRecord::Base

  class << self

    private
    
    alias :sanitize_sql_orig :sanitize_sql
    def sanitize_sql( arg ) # :nodoc:
      return sanitize_sql_orig( arg ) if arg.nil?
      if arg.respond_to?( :to_sql )
        arg = sanitize_sql_by_way_of_duck_typing( arg )
      elsif arg.is_a?( Hash )
        arg = sanitize_sql_from_hash( arg ) 
      elsif arg.is_a?( Array ) and arg.size == 2 and arg.first.is_a?( String ) and arg.last.is_a?( Hash )
      arg = sanitize_sql_from_string_and_hash( arg ) 
      end
      sanitize_sql_orig( arg )
    end
    
    def sanitize_sql_by_way_of_duck_typing( arg ) #: nodoc:
      arg.to_sql( caller )
    end

    def sanitize_sql_from_string_and_hash( arr ) # :nodoc:
      return arr if arr.first =~ /\:[\w]+/        
      arr2 = sanitize_sql_from_hash( arr.last )
      if arr2.empty?
        conditions = arr.first
      else
        conditions = [  arr.first <<  " AND (#{arr2.first})" ]
        conditions.push( *arr2[1..-1] )
      end
      conditions
    end
    
    def sanitize_sql_from_hash( hsh ) #:nodoc:
      conditions, values = [], []

      hsh.each_pair do |key,val|
        if val.respond_to?( :to_sql )  
          conditions << sanitize_sql_by_way_of_duck_typing( val ) 
          next
        else
          sql = nil
          result = ActiveRecord::Extensions.process( key, val, self )
          if result
            conditions << result.sql
            values.push( result.value ) 
          else
            conditions << "#{table_name}.#{connection.quote_column_name(key.to_s)} #{attribute_condition( val )} "
            values << val
          end
        end
      end
        
      conditions = conditions.join( ' AND ' )
      return [] if conditions.size == 1 and conditions.first.empty?
      [ conditions, *values ]
    end
       
  end
  
end
