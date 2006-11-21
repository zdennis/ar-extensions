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

 private

  class << self

    alias :sanitize_sql_orig :sanitize_sql
    def sanitize_sql( arg )
      return sanitize_sql_orig( arg ) if arg.nil?
      arg = sanitize_sql_by_way_of_duck_typing( arg ) if arg.respond_to?( :to_sql )
      arg = sanitize_sql_from_hash( arg ) if arg.is_a?( Hash )
      arg = sanitize_sql_from_string_and_hash( arg ) if arg.size == 2 and arg.first.is_a?( String ) and arg.last.is_a?( Hash )
      result = sanitize_sql_orig( arg )
    end
    
    def sanitize_sql_by_way_of_duck_typing( arg )
      arg.to_sql( caller )
    end

    def sanitize_sql_from_string_and_hash( arr )
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
    
    def sanitize_sql_from_hash( hsh )
      conditions, values = [], []
      
      hsh.each_pair do |key,val|
        if val.respond_to?( :to_sql )  
          conditions << sanitize_sql_by_way_of_duck_typing( val ) 
          next
        else
          sql = nil
          result = ActiveRecord::Extensions.process( key, val, self )
          
          if result
            conditions << result.sql if result.sql
            values.push( result.value ) if result.value
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
