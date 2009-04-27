module ActiveRecord::Extensions::TemporaryTableSupport # :nodoc:
  def supports_temporary_tables? #:nodoc:
    true
  end
end

class ActiveRecord::Base
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
  # <tt>:table_name</tt>::the desired name of the temporary table. If not supplied 
  #   then a name of "temp_" + the current table_name of the current model 
  #   will be used.
  # <tt>:like</tt>:: the table model you want to base the temporary tables 
  #   structure off from. If this is not supplied then the table_name of the 
  #   current model will be used.
  # <tt>:model_name</tt>:: the name of the model you want to use for the temporary 
  #   table. This must be compliant with Ruby's naming conventions for 
  #   constants. If this is not supplied a rails-generated table name will 
  #   be created which is based off from the table_name of the temporary table. 
  #   IE: Account.create_temporary_table creates the TempAccount model class
  #
  # ==== Example 1, using defaults
  #
  #  class Project < ActiveRecord::Base
  #  end
  #
  #  > t = Project.create_temporary_table
  #  > t.class
  #  => "TempProject"
  #  > t.superclass
  #  => Project
  #
  # This creates a temporary table named 'temp_projects' and creates a constant
  # name TempProject. The table structure is copied from the 'projects' table. 
  # TempProject is a subclass of Project as you would expect.
  #
  # ==== Example 2, using <tt>:table_name</tt> and <tt>:model options</tt>
  #
  #   Project.create_temporary_table :table_name => 'my_projects', :model => 'MyProject'
  #
  # This creates a temporary table named 'my_projects' and creates a constant named
  # MyProject. The table structure is copied from the 'projects' table.
  #
  # ==== Example 3, using <tt>:like</tt>
  #
  #   ActiveRecord::Base.create_temporary_table :like => Project 
  #  
  # This is the same as calling Project.create_temporary_table.
  #
  # ==== Example 4, using block form
  #
  #   Project.create_temporary_table do |t|
  #     # ...
  #   end
  # 
  # Using the block form will automatically drop the temporary table
  # when the block exits. +t+ which is passed into the block is the temporary
  # table class. In the above example +t+ equals TempProject. The block form
  # can be used with all of the available options.
  #
  # === See
  #
  # * +drop+
  #
  ######################################################################
  def self.create_temporary_table(opts={})
    opts[:temporary]  ||= !opts[:permanent]
    opts[:like]       ||= self
    opts[:table_name] ||= "temp_#{self.table_name}"
    opts[:model_name] ||= ActiveSupport::Inflector.classify(opts[:table_name])

    if Object.const_defined?(opts[:model_name])
      raise Exception, "Model #{opts[:model_name]} already exists!"
    end

    like_table_name = opts[:like].table_name || self.table_name

    connection.execute <<-SQL
      CREATE #{opts[:temporary] ? 'TEMPORARY' : ''} TABLE #{opts[:table_name]}
        LIKE #{like_table_name}
    SQL
    
    # Sample evaluation:
    #
    #   class ::TempFood < Food
    #     set_table_name :temp_food
    #
    #     def self.drop
    #       connection.execute "DROP TABLE temp_foo"
    #       Object.send(:remove_const, self.name.to_sym)
    #     end
    #   end
    class_eval(<<-RUBY, __FILE__, __LINE__)
      class ::#{opts[:model_name]} < #{self.name}
        set_table_name :#{opts[:table_name]}

        def self.drop
          connection.execute "DROP TABLE #{opts[:table_name]};"
          Object.send(:remove_const, self.name.to_sym)
        end
      end
    RUBY

    model = Object.const_get(opts[:model_name])

    if block_given?
      begin
        yield(model)
      ensure
        model.drop
      end
    else
      return model
    end
  end
end
