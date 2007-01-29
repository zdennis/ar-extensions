
class ActiveRecord::Base
  @@temporary_table_hsh ||= {}		
	
  ######################################################################
  # Creates a temporary in memory-only table given the passed in options hash.
  # The temporary table is created based off from another table. (Currently
  # defining a new temporary table which is not based off from an existing
  # table is not supported.) This method returns the constant for the new
  # new model. This currently is only supported when using the MySQL Adapter. 
  # The temporary table thatis created has the scope that is set by the MySQL 
  # server. 
  # 
  # === Parameters
  # * options - the options hash used to define the temporary table. 
  # 
  # ==== Available Options
  # * :table_name - the desired name of the temporary table. If not supplied
  #   then a name of "temp_" + the current table_name of the current model
  #   will be used.
  # * :like - the table model you want to base the temporary tables
  #   structure off from. If this is not supplied then the table_name of the
  #   current model will be used.
  # * :model_name - the name of the model you want to use for the temporary
  #   table. This must be compliant with Ruby's naming conventions for 
  #   constants. If this is not supplied a rails-generated table name will
  #   be created which is based off from the table_name of the temporary table.
  #
  # === Example
  # 	Table::create_temporary_table => TempTable
  #	Table.create_temporary_table( :table_name=>'my_temp_table' ) => MyTempTable
  #	Table.create_temporary_table( :table_name=>'my_temp_table', :model=>:ATempTable ) => ATempTable
  #	Table.create_temporary_table( :model=>:MyTempTable ) => MyTempTable
  #	Table.create_temporary_table( :table_name=>'my_temp_table', :like=>AnotherTable ) => MyTempTable
  #
  #	Table.create_temporary_table( :like=>'AnotherTable' ) # wrong!
  #	Table.create_temporary_table( :like=>:AnotherTable ) => # wrong!
  #
  # === Exceptions
  # * Exception - if the MySQL Adapter is not being used
  # * Mysql::Error - if the passed in model's table name is unknown to the
  #   database
  #
  # === See
  # * drop
  # * database_check
  ######################################################################
  def self.create_temporary_table( options={} )
    options[:table_name] = "temp_#{self.table_name}" unless options[:table_name]
    options[:like] = self unless options[:like]	
    options[:temporary] = true if not options[:permanent] and not options.has_key?( :temporary )
    table_name = options[:table_name]
    model_name = options[:model_name] || Inflector.classify( table_name )	
    raise Exception.new( "Model #{model_name} already exists! \n" ) if Object.const_defined? model_name 
    
    like_table_name = options[:like].table_name || self.table_name
    sql = "CREATE #{options[:temporary] ? 'TEMPORARY' : ''} TABLE #{table_name} LIKE #{like_table_name}"
    connection.execute( sql )		
    
    eval "class ::#{model_name} < #{ActiveRecord::TemporaryTable.name}
					set_table_name :#{table_name}
				end"

    @@temporary_table_hsh[ model = Object.const_get( model_name ) ] = true

    if block_given?
      yield model
      model.drop
      nil
    else
      model
    end
  end

end

class ActiveRecord::TemporaryTable < ActiveRecord::Base
  
  def self.drop
    if @@temporary_table_hsh[ self ]
      sql = 'DROP TABLE ' + self.table_name + ';'
      connection.execute( sql )
      Object.send( :remove_const, self.name.to_sym )
      @@temporary_table_hsh.delete( self )
    else
      raise StandardError.new "Trying to drop nonexistance temporary table: #{self.name}"
    end
  end
  
end


  
