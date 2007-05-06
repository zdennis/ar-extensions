module ActiveRecord::Extensions::ConnectionAdapters ; end

module ActiveRecord::Extensions::Import #:nodoc:
  
  module ImportSupport #:nodoc:
    def supports_import? #:nodoc:
      true
    end
  end
  
  module OnDuplicateKeyUpdateSupport #:nodoc:
    def supports_on_duplicate_key_update? #:nodoc:
      true
    end
  end
  
end

class ActiveRecord::Base
  class << self
  
    # Returns true if the current database connection adapter
    # supports import functionality, otherwise returns false.
    def supports_import?
      connection.supports_import?
    rescue NoMethodError
      false
    end
    
    # Returns true if the current database connection adapter
    # supports on duplicate key update functionality, otherwise
    # returns false.
    def supports_on_duplicate_key_update?
      connection.supports_on_duplicate_key_update?
    rescue NoMethodError
      false
    end
    
    # Imports a collection of values to the database.  
    #
    # This is more efficient than using ActiveRecord::Base#create or
    # ActiveRecord::Base#save multiple times. This method works well if
    # you want to create more than one record at a time and do not care
    # about having ActiveRecord objects returned for each record
    # inserted. 
    #
    # This can be used with or without validations. It does not utilize
    # the ActiveRecord::Callbacks during creation/modification while
    # performing the import.
    #
    # == Usage
    #  Model.import array_of_models
    #  Model.import column_names, array_of_values
    #  Model.import column_names, array_of_values, options
    # 
    # ==== Model.import array_of_models
    # 
    # With this form you can call _import_ passing in an array of model
    # objects that you want updated.
    #
    # ==== Model.import column_names, array_of_values
    #
    # The first parameter +column_names+ is an array of symbols or
    # strings which specify the columns that you want to update.
    #
    # The second parameter, +array_of_values+, is an array of
    # arrays. Each subarray is a single set of values for a new
    # record. The order of values in each subarray should match up to
    # the order of the +column_names+.
    #
    # ==== Model.import column_names, array_of_values, options
    #
    # The first two parameters are the same as the above form. The third
    # parameter, +options+, is a hash. This is optional. Please see
    # below for what +options+ are available.
    #
    # == Options
    # * +validate+ - true|false, tells import whether or not to use \
    #    ActiveRecord validations. Validations are enforced by default.
    # * +on_duplicate_key_update+ - an Array or Hash, tells import to \
    #    use MySQL's ON DUPLICATE KEY UPDATE ability. See On Duplicate\
    #    Key Update below.
    # * +synchronize+ - an array of ActiveRecord instances for the model
    #   that you are currently importing data into. This synchronizes
    #   existing model instances in memory with updates from the import.
    #
    # == Examples  
    #  class BlogPost < ActiveRecord::Base ; end
    #  
    #  # Example using array of model objects
    #  posts = [ BlogPost.new :author_name=>'Zach Dennis', :title=>'AREXT',
    #            BlogPost.new :author_name=>'Zach Dennis', :title=>'AREXT2',
    #            BlogPost.new :author_name=>'Zach Dennis', :title=>'AREXT3' ]
    #  BlogPost.import posts
    #
    #  # Example using column_names and array_of_values
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
    #  BlogPost.import columns, values 
    #
    #  # Example using column_names, array_of_value and options
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
    #  BlogPost.import( columns, values, :validate => false  )
    #
    #  # Example synchronizing existing instances in memory
    #  post = BlogPost.find_by_author_name( 'zdennis' )
    #  puts post.author_name # => 'zdennis'
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'yoda', 'test post' ] ]
    #  BlogPost.import posts, :synchronize=>[ post ]
    #  puts post.author_name # => 'yoda'
    #
    # == On Duplicate Key Update (MySQL only)
    #
    # The :on_duplicate_key_update option can be either an Array or a Hash. 
    # 
    # ==== Using an Array
    #
    # The :on_duplicate_key_update option can be an array of column
    # names. The column names are the only fields that are updated if
    # a duplicate record is found. Below is an example:
    #
    #   BlogPost.import columns, values, :on_duplicate_key_update=>[ :date_modified, :content, :author ]
    #
    # ====  Using A Hash
    #
    # The :on_duplicate_key_update option can be a hash of column name
    # to model attribute name mappings. This gives you finer grained
    # control over what fields are updated with what attributes on your
    # model. Below is an example:
    #   
    #   BlogPost.import columns, attributes, :on_duplicate_key_update=>{ :title => :title } 
    #  
    def import( *args )
      options = { :validate=>true }
      options.merge!( args.pop ) if args.last.is_a? Hash
      
      # assume array of model objects
      if args.last.is_a?( Array ) and args.last.first.is_a? ActiveRecord::Base
        if args.length == 2
          models = args.last
          column_names = args.first
        else
          models = args.first
          column_names = self.column_names.dup
          column_names.delete( self.primary_key ) unless options[ :on_duplicate_key_update ]
        end
        
        array_of_attributes = models.inject( [] ) do |arr,model|
          attributes = []
          column_names.each do |name| 
            attributes << model.send( "#{name}_before_type_cast" ) 
          end
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
      number_of_inserts = if is_validating
        import_with_validations( column_names, array_of_attributes, options )
      else
        import_without_validations_or_callbacks( column_names, array_of_attributes, options )
      end
      
      if options[:synchronize]
        synchronize( options[:synchronize] )
      end
      
      number_of_inserts
    end
    
    # TODO import_from_table needs to be implemented. 
    def import_from_table( options ) # :nodoc:
    end
    
    # Imports the passed in +column_names+ and +array_of_attributes+
    # given the passed in +options+ Hash with validations. Returns an
    # array of instances that failed validations. See
    # ActiveRecord::Base.import for more information on
    # +column_names+, +array_of_attributes+ and +options+.
    def import_with_validations( column_names, array_of_attributes, options={} )
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
    
    # Imports the passed in +column_names+ and +array_of_attributes+
    # given the passed in +options+ Hash. This will return the number
    # of insert operations it took to create these records without
    # validations or callbacks. See ActiveRecord::Base.import for more
    # information on +column_names+, +array_of_attributes_ and
    # +options+.
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

    
    private
    
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
end
