
module ActiveRecord::Extensions::TemporaryTableSupport # :nodoc:
  def supports_temporary_tables? #:nodoc:
    true
  end
end


class ActiveRecord::Base
  @@temporary_table_hsh ||= {}		

  # Returns true if the underlying database connection supports temporary tables
  def self.supports_temporary_tables?
    connection.supports_temporary_tables?
  rescue NoMethodError
    false
  end
  
  ######################################################################
  # Creates a temporary table given the passed in options hash.  The
  # temporary table is created based off from another table the
  # current model class. This method returns the constant for the new
  # new model. This can also be used with block form (see below).
  # 
  # == Parameters
  # * options - the options hash used to define the temporary table. 
  # 
  # ==== Options
  # * :table_name - the desired name of the temporary table. If not supplied \
  #   then a name of "temp_" + the current table_name of the current model \
  #   will be used.
  # * :like - the table model you want to base the temporary tables \
  #   structure off from. If this is not supplied then the table_name of the \
  #   current model will be used.
  # * :model_name - the name of the model you want to use for the temporary \
  #   table. This must be compliant with Ruby's naming conventions for \
  #   constants. If this is not supplied a rails-generated table name will \
  #   be created which is based off from the table_name of the temporary table. \
  #   IE: Account.create_temporary_table creates the TempAccount model class
  #
  # ==== Example 1, using defaults
  #  class Project < ActiveRecord::Base ; end
  #
  #  Project.create_temporary_table
  #
  # This creates a temporary table named 'temp_projects' and creates a constant
  # name TempProject. The table structure is copied from the _projects_ table.
  #
  # ==== Example 2, using :table_name and :model options
  #   Project.create_temporary_table :table_name=>'my_projects', :model=>'MyProject'
  #
  # This creates a temporary table named 'my_projects' and creates a constant named
  # MyProject. The table structure is copied from the _projects_ table.
  #
  # ==== Example 3, using :like
  #   ActiveRecord::Base.create_temporary_table :like=>Project 
  #  
  # This is the same as calling Project.create_temporary_table.
  #
  # ==== Example 4, using block form
  #   Project.create_temporary_table do |t|
  #     # ...
  #   end
  # 
  # Using the block form will automatically drop the temporary table
  # when the block exits. _t_ which is passed into the block is the temporary
  # table class. In the above example _t_ equals TempProject. The block form
  # can be used with all of the available options.
  #
  # === See
  # * drop
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
  
  # Drops a temporary table from the database and removes
  # the temporary table constant.
  #
  # ==== Example
  #   Project.create_temporary_table
  #   Object.const_defined?( :TempProject ) # => true
  #   TempProject.drop
  #   Object.const_defined?( :TempProject ) # => false
  #
  def self.drop
    if @@temporary_table_hsh[ self ]
      sql = 'DROP TABLE ' + self.table_name + ';'
      connection.execute( sql )
      Object.send( :remove_const, self.name.to_sym )
      @@temporary_table_hsh.delete( self )
    else
      raise StandardError.new( "Trying to drop nonexistance temporary table: #{self.name}" )
    end
  end
  
end

