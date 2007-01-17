module ActiveRecord::Extensions::ConnectionAdapters ; end
module ActiveRecord::Extensions::Import
  module ImportSupport
    def supports_import?
      true
    end
  end
  
  module OnDuplicateKeyUpdateSupport
    def supports_on_duplicate_key_update?
      true
    end
  end
end

module ActiveRecord::Extensions::Import::Base

  def supports_import?
    connection.supports_import?
  rescue NoMethodError
    false
  end
  
  def supports_on_duplicate_key_update?
    connection.supports_on_duplicate_key_update?
  rescue NoMethodError
    false
  end
  
  # Imports a collection of values to the database. This is more efficient than
  # using ActiveRecord::Base#create or ActiveRecord::Base#save multiple times. This
  # method works well if you want to create more then one record at a time and do not
  # care about having ActiveRecord objects returned for each record inserted. This can
  # be used with or without validations. It does not utilize the ActiveRecord::Callbacks
  # during creation/modification while performing the import.
  #
  # == Usage
  #  Model.import( column_names, array_of_values )
  #  Model.import( column_names, array_of_values, options )
  # 
  # In the above examples +column_names+ is an Array of column/field names for the model
  # you want to insert values to. The +column_names+ can be an array of Strings or 
  # Symbols. 
  #
  # The +array_of_values+ is an Array of Arrays. Each inner Array is considered
  # a single set of values for a new record. The order of the values should match up to the
  # order of the +column_names+.
  #
  # The +options+ in the second usage example is a Hash. Please see below for what +options+
  # are available. This is optional.
  #
  # == Available Options
  # * +validate+ - true|false, tells import whether or not to use ActiveRecord validations. Validations \
  #    are enforced by default.
  # * +on_duplicate_key_update+ - an Array or Hash, tells import to use MySQL's ON DUPLICATE KEY UPDATE ability.  \
  #    See On Duplicate Key Update below.
  #
  # == Examples  
  #  # Example 1
  #  columns = [ :author_name, :title ]
  #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
  #  MyModel.import( columns, values )
  #
  #  # Example 2
  #  columns = [ :author_name, :title ]
  #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
  #  MyModel.import( columns, values, :validate=> true )
  #
  #  # Example 3
  #  columns = [ :author_name, :title ]
  #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
  #  MyModel.import( columns, values, :validate=> false )
  #
  # == Validating Imports
  # Validating imports can be done by passing in the :validate flag in the options Hash. By
  # default import works with validation. Validations will return an Array of records that
  # do not pass validation as ActiveRecord objects. It will return an empty array if
  # all records pass validation. This is not database adapter specific.
  # 
  # == On Duplicate Key Update (MySQL only)
  # The :on_duplicate_key_update option can be either an Array or a Hash. 
  # 
  # === Using An Array
  # If it's an Array it should be an Array of Symbols or Strings of the columns/fields to update if an 
  # row cannot be created because it is a duplicate. The below example will update the address
  # of each Person if a row already exists in the database for the person. It will not update
  # the Person's first or last name.
  #
  #   columns = [ :first_name, :last_name, :address, :city, :state, :zip ]
  #   values = [ 
  #     [ 'Zach', 'Dennis', '12345 Abc St.', 'SomeCity', 'MI', '55555' ],
  #     [ 'John', 'Doe', '22334 Doe St.', 'DoeVille', 'MI', '12345' ] ]
  #   Person.import( columns, values, :on_duplicate_key_update=>[ :address, :city, :state ]
  #
  # === Using A Hash
  # If a Hash is passed in it should be an map of column to column mappings that should be
  # be updated. Below is an example that will map the first_name of existing records to 
  # the last_name that is passed in the attributes array. This is not a very useful
  # example, but is intended to show that you can specify what column in the passed
  # in values should be used to update a particular field in database.
  #   
  #   MyModel.import( columns, 
  #     attributes, 
  #     :on_duplicate_key_update=>{ 'first_name'=>'last_name' } )
  #  
  def import( *args )
    options = { :validate=>true }
    options.merge!( args.pop ) if args.last.is_a? Hash

    # assume array of model objects
    if args.size == 1 and args.first.is_a?( Array )
      models = args.first
      column_names = models.first.class.columns.map{ |c| c.name }
      array_of_attributes = models.inject( [] ) do |arr,model|
        attributes = []
        column_names.each{ |name| attributes << model.send( "#{name}_before_type_cast" ) }
        arr << attributes
      end
    # supports 2-element array and array
    elsif args.size == 2 and args.first.is_a?( Array ) and args.last.is_a?( Array )
      column_names, array_of_attributes = args
    else
      raise ArgumentError.new( "Invalid arguments!" )
    end
    
    is_validating = options.delete( :validate )

    # dup the passed in array so we don't modify it unintentionally
    array_of_attributes = array_of_attributes.dup
    if is_validating
      import_with_validations( column_names, array_of_attributes, options )
    else
      import_without_validations_or_callbacks( column_names, array_of_attributes, options )
    end
  end

  # Imports the passed in +column_names+ and +array_of_attributes+ given the passed in +options+ Hash
  # with validations. Returns an array of instances that failed validations.
  def import_with_validations( column_names, array_of_attributes, options={} ) # :nodoc:
    failed_instances = []

    # create instances for each of our column/value sets
    arr = validations_array_for_column_names_and_attributes( column_names, array_of_attributes )    
    
    # keep track of the instance and the position it is currently at. if this fails
    # validation we'll use the index to remove it from the array_of_attributes
    arr.each_with_index do |hsh,i| 
      instance = new( hsh )
      if not instance.valid?
        array_of_attributes[ i ] = nil
        failed_instances << instance
      end    
    end
    array_of_attributes.compact!

    if not array_of_attributes.empty?
      import_without_validations_or_callbacks( column_names, array_of_attributes, options )
    end
    failed_instances   
  end
  
  # Imports the passed in +column_names+ and +array_of_attributes+ given the passed in 
  # +options+ Hash. This will return the number of insert operations it took to create these 
  # records without validations or callbacks. 
  def import_without_validations_or_callbacks( column_names, array_of_attributes, options={} )
    escaped_column_names = quote_column_names( column_names )
    columns = []
    array_of_attributes.first.each_with_index { |arr,i| columns << columns_hash[ column_names[i] ] }
    
    if not supports_import?
      columns_sql = "(" + escaped_column_names.join( ',' ) + ")"
      insert_statements, values = [], []
      array_of_attributes.each do |arr|
        my_values = []
        arr.each_with_index do |val,j|
          my_values << connection.quote( val, columns[j] )
        end
        insert_statements << "INSERT INTO #{self.table_name} #{columns_sql} VALUES(" + my_values.join( ',' ) + ")"
        connection.execute( insert_statements.last )
      end
      return
    else


    # generate the sql
    insert_sql = connection.multiple_value_sets_insert_sql( table_name, escaped_column_names, options )

    values_sql = connection.values_sql_for_column_names_and_attributes( columns, array_of_attributes )
    post_sql_statements = connection.post_sql_statements( table_name, options )
    
    # perform the inserts
    number_of_inserts = connection.insert_many( 
      [ insert_sql, post_sql_statements ].flatten, 
      values_sql,
      "#{self.class.name} Create Many Without Validations Or Callbacks" )
    end
  end
      
  # Returns an array of quoted column names
  def quote_column_names( names ) 
    names.map{ |name| connection.quote_column_name( name ) }
  end
 
  # Returns an Array of Hashes for the passed in +column_names+ and +array_of_attributes+.
  def validations_array_for_column_names_and_attributes( column_names, array_of_attributes ) # :nodoc:
    arr = []
    array_of_attributes.each do |attributes|
      c = 0
      hsh = attributes.inject( {} ){|hsh,attr| hsh[ column_names[c] ] = attr ; c+=1 ; hsh }
      arr << hsh
    end
    arr
  end
  
end

ActiveRecord::Base.extend( ActiveRecord::Extensions::Import::Base )

