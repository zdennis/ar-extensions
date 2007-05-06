module ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter # :nodoc:

  include ActiveRecord::Extensions::Import::ImportSupport  
  include ActiveRecord::Extensions::Import::OnDuplicateKeyUpdateSupport
  
  # Returns an array of post SQL statements given the passed in options.
  def post_sql_statements( table_name, options ) # :nodoc:
    post_sql_statements = []
    if options[:on_duplicate_key_update]
      post_sql_statements << sql_for_on_duplicate_key_update( table_name, options[:on_duplicate_key_update] )
    end
    post_sql_statements
  end
  
  def multiple_value_sets_insert_sql( table_name, column_names, options ) # :nodoc:    
    "INSERT #{options[:ignore] ? 'IGNORE ':''} INTO #{table_name} (#{column_names.join(',')}) VALUES "
  end
  
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

  # Returns SQL the VALUES for an INSERT statement given the passed in +columns+ 
  # and +array_of_attributes+.
  def values_sql_for_column_names_and_attributes( columns, array_of_attributes )   # :nodoc:
    values = []
    array_of_attributes.each do |arr|
      my_values = []
      arr.each_with_index do |val,j|
        my_values << quote( val, columns[j] )
      end
      values << my_values
    end   
    values_arr = values.map{ |arr| '(' + arr.join( ',' ) + ')' }
  end
    
end

ActiveRecord::ConnectionAdapters::MysqlAdapter.send( 'include', ActiveRecord::Extensions::ConnectionAdapters::MysqlAdapter )
