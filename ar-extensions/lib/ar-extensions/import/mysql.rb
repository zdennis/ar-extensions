module ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter # :nodoc:

  include ActiveRecord::Extensions::Import::ImportSupport  
  include ActiveRecord::Extensions::Import::OnDuplicateKeyUpdateSupport
    
  # Returns a generated ON DUPLICATE KEY UPDATE statement given the passed
  # in +args+. 
  def sql_for_on_duplicate_key_update( table_name, *args ) # :nodoc:
    sql = ' ON DUPLICATE KEY UPDATE '
    arg = args.first
    if arg.is_a?( Array )
      sql << sql_for_on_duplicate_key_update_as_array( table_name, arg )
    elsif arg.is_a?( Hash )
      sql << sql_for_on_duplicate_key_update_as_hash( table_name, arg )
    else
      raise ArgumentError.new( "Expected Array or Hash" )
    end
    sql
  end

  def sql_for_on_duplicate_key_update_as_array( table_name, arr )  # :nodoc:
    qt = quote_column_name( table_name )
    results = arr.map do |column|
      qc = quote_column_name( column )
      "#{qt}.#{qc}=VALUES(#{qc})"        
    end
    results.join( ',' )
  end
  
  def sql_for_on_duplicate_key_update_as_hash( table_name, hsh ) # :nodoc:
    sql = ' ON DUPLICATE KEY UPDATE '
    qt = quote_column_name( table_name )
    results = hsh.map do |column1, column2|
      qc1 = quote_column_name( column1 )
      qc2 = quote_column_name( column2 )
      "#{qt}.#{qc1}=VALUES( #{qc2} )"
    end
    results.join( ',')
  end  

end

ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  include ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter
end
