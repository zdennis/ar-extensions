# ActiveRecord::Extensions::CreateAndUpdate extends ActiveRecord adding additionaly functionality for
# insert and updates. Methods +create+, +update+, and +save+ accept
# additional hash map of parameters to allow customization of database access.
#
# Include the appropriate adapter file in <tt>environment.rb</tt> to access this functionality
#   require 'ar-extenstion/create_and_update/mysql'
#
# === Options
# * <tt>:pre_sql</tt> inserts SQL before the +INSERT+ or +UPDATE+ command
# * <tt>:post_sql</tt> appends additional SQL to the end of the statement
# * <tt>:keywords</tt> additional keywords to follow the command. Examples
#   include +LOW_PRIORITY+, +HIGH_PRIORITY+, +DELAYED+
# * <tt>:on_duplicate_key_update</tt> - an array of fields (or a custom string) specifying which parameters to
#   update if there is a duplicate row (unique key violoation)
# * <tt>:ignore => true </tt> - skips insert or update for duplicate existing rows on a unique key value
# * <tt>:command</tt> an additional command to replace +INSERT+ or +UPDATE+
# * <tt>:reload</tt> - If a duplicate is ignored (+ignore+) or updated with
#   +on_duplicate_key_update+, the instance is reloaded to reflect the data
#   in the database. If the record is not reloaded, it may contain stale data and
#   <tt>stale_record?</tt> will evaluate to true. If the object is discared after
#   create or update, it is preferrable to avoid reloading the record to avoid
#   superflous queries
# * <tt>:duplicate_columns</tt> - an Array required with +reload+ to specify the columns used
#   to locate the duplicate record. These are the unique key columns.
#   Refer to the documentation under the +duplicate_columns+ method.
#
#
# === Create Examples
# Assume that there is a unique key on the +name+ field
#
# Create a new giraffe, and ignore the error if a giraffe already exists
# If a giraffe exists, then the instance of animal is stale, as it may not
# reflect the data in the database.
#  animal = Animal.create!({:name => 'giraffe', :size => 'big'}, :ignore => true)
#
#
# Create a new giraffe; update the existing +size+ and +updated_at+ fields if the
# giraffe already exists. The instance of animal is not stale and reloaded
# to reflect the content in the database.
#  animal = Animal.create({:name => 'giraffe', :size => 'big'},
#                 :on_duplicate_key_update => [:size, :updated_at],
#                 :duplicate_columns => [:name], :reload => true)
#
# Save a new giraffe, ignoring existing duplicates and inserting a comment
# in the SQL before the insert.
#  giraffe = Animal.new(:name => 'giraffe', :size => 'small')
#  giraffe.save!(:ignore => true, :pre_sql => '/* My Comment */')
#
#
# === Update Examples
# Update the giraffe with the low priority keyword
#  big_giraffe.update(:keywords => 'LOW_PRIORITY')
#
# Update an existing record. If a duplicate exists, it is updated with the
# fields specified by +:on_duplicate_key_update+. The original instance(big_giraffe) is
# deleted, and the instance is reloaded to reflect the database (giraffe).
#  big_giraffe = Animal.create!(:name => 'big_giraffe', :size => 'biggest')
#  big_giraffe.name = 'giraffe'
#  big_giraffe.save(:on_duplicate_key_update => [:size, :updated_at],
#                   :duplicate_columns => [:name], :reload => true)
#
# === Misc
#
# <tt>stale_record?</tt> - returns true if the record is stale
# Example: <tt>animal.stale_record?</tt>
#
# == Developers
# * Blythe Dunham http://blythedunham.com
#
# == Homepage
# * Project Site: http://www.continuousthinking.com/tags/arext
# * Rubyforge Project: http://rubyforge.org/projects/arext
# * Anonymous SVN: svn checkout svn://rubyforge.org/var/svn/arext
#

module ActiveRecord::Extensions::ConnectionAdapters; end

module ActiveRecord
  module Extensions


    # ActiveRecord::Extensions::CreateAndUpdate extends ActiveRecord adding additionaly functionality for
    # insert and updates. Methods +create+, +update+, and +save+ accept
    # additional hash map of parameters to allow customization of database access.
    #
    # Include the appropriate adapter file in <tt>environment.rb</tt> to access this functionality
    #   require 'ar-extenstion/create_and_update/mysql'
    #
    # === Options
    # * <tt>:pre_sql</tt> inserts +SQL+ before the +INSERT+ or +UPDATE+ command
    # * <tt>:post_sql</tt> appends additional +SQL+ to the end of the statement
    # * <tt>:keywords</tt> additional keywords to follow the command. Examples
    #   include +LOW_PRIORITY+, +HIGH_PRIORITY+, +DELAYED+
    # * <tt>:on_duplicate_key_update</tt> - an array of fields (or a custom string) specifying which parameters to
    #   update if there is a duplicate row (unique key violoation)
    # * <tt>:ignore => true </tt> - skips insert or update for duplicate existing rows on a unique key value
    # * <tt>:command</tt> an additional command to replace +INSERT+ or +UPDATE+
    # * <tt>:reload</tt> - If a duplicate is ignored (+ignore+) or updated with
    #   +on_duplicate_key_update+, the instance is reloaded to reflect the data
    #   in the database. If the record is not reloaded, it may contain stale data and
    #   <tt>stale_record?</tt> will evaluate to true. If the object is discared after
    #   create or update, it is preferrable to avoid reloading the record to avoid
    #   superflous queries
    # * <tt>:duplicate_columns</tt> - an Array required with +reload+ to specify the columns used
    #   to locate the duplicate record. These are the unique key columns.
    #   Refer to the documentation under the +duplicate_columns+ method.
    #
    #
    # === Create Examples
    # Assume that there is a unique key on the +name+ field
    #
    # Create a new giraffe, and ignore the error if a giraffe already exists
    # If a giraffe exists, then the instance of animal is stale, as it may not
    # reflect the data in the database.
    #  animal = Animal.create!({:name => 'giraffe', :size => 'big'}, :ignore => true)
    #
    #
    # Create a new giraffe; update the existing +size+ and +updated_at+ fields if the
    # giraffe already exists. The instance of animal is not stale and reloaded
    # to reflect the content in the database.
    #  animal = Animal.create({:name => 'giraffe', :size => 'big'},
    #                 :on_duplicate_key_update => [:size, :updated_at],
    #                 :duplicate_columns => [:name], :reload => true)
    #
    # Save a new giraffe, ignoring existing duplicates and inserting a comment
    # in the SQL before the insert.
    #  giraffe = Animal.new(:name => 'giraffe', :size => 'small')
    #  giraffe.save!(:ignore => true, :pre_sql => '/* My Comment */')
    #
    #
    # === Update Examples
    # Update the giraffe with the low priority keyword
    #  big_giraffe.update(:keywords => 'LOW_PRIORITY')
    #
    # Update an existing record. If a duplicate exists, it is updated with the
    # fields specified by +:on_duplicate_key_update+. The original instance(big_giraffe) is
    # deleted, and the instance is reloaded to reflect the database (giraffe).
    #  big_giraffe = Animal.create!(:name => 'big_giraffe', :size => 'biggest')
    #  big_giraffe.name = 'giraffe'
    #  big_giraffe.save(:on_duplicate_key_update => [:size, :updated_at],
    #                   :duplicate_columns => [:name], :reload => true)
    #
    module CreateAndUpdate

      class NoDuplicateFound < Exception; end

      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
        base.extend(ActiveRecord::Extensions::SqlGeneration)

        #alias chain active record methods if they have not already
        #been chained
        unless base.method_defined?(:save_without_extension)
          base.class_eval do
            [:save, :update, :save!, :create_or_update, :create].each { |method|  alias_method_chain method, :extension }

            class << self
              [:create, :create!].each {|method| alias_method_chain method, :extension }
            end

          end
        end
      end

      def supports_create_and_update? #:nodoc:
        true
      end

      module ClassMethods#:nodoc:

        # Creates an object, instantly saves it as a record (if the validation permits it), and returns it. If the save
        # fails under validations, the unsaved object is still returned.
        def create_with_extension(attributes = nil, options={}, &block)#:nodoc:
          return create_without_extension(attributes, &block) unless options.any?
          if attributes.is_a?(Array)
            attributes.collect { |attr| create(attr, &block) }
          else
            object = new(attributes)
            yield(object) if block_given?
            object.save(options)
            object
          end
        end

        # Creates an object just like Base.create but calls save! instead of save
        # so an exception is raised if the record is invalid.
        def create_with_extension!(attributes = nil, options={}, &block)#:nodoc:
          return create_without_extension!(attributes, &block) unless options.any?
          create_with_extension(attributes, options.merge(:raise_exception => true), &block)
        end

      end#ClassMethods


      def save_with_extension(options={})#:nodoc:

        #invoke save_with_validation if the argument is not a hash
        return save_without_extension(options) if !options.is_a?(Hash)
        return save_without_extension unless options.any?

        perform_validation = options.delete(:perform_validation)
        raise_exception = options.delete(:raise_exception)

        if (perform_validation.is_a?(FalseClass)) || valid?
          raise ActiveRecord::ReadOnlyRecord if readonly?
          create_or_update(options)
        else
          raise ActiveRecord::RecordInvalid.new(self) if raise_exception
          false
        end
      end

      def save_with_extension!(options={})#:nodoc:

        return save_without_extension!(options) if !options.is_a?(Hash)
        return save_without_extension! unless options.any?

        save_with_extension(options.merge(:raise_exception => true)) || raise(ActiveRecord::RecordNotSaved)
      end

      #overwrite the create_or_update to call into
      #the appropriate method create or update with the new options
      #call the callbacks here
      def create_or_update_with_extension(options={})#:nodoc:
        return create_or_update_without_extension unless options.any?

        return false if callback(:before_save) == false
        raise ReadOnlyRecord if readonly?
        result = new_record? ? create(options) : update(@attributes.keys, options)
        callback(:after_save)

        result != false
      end


      # Updates the associated record with values matching those of the instance attributes.
      def update_with_extension(attribute_names = @attributes.keys, options={})#:nodoc:

        return update_without_extension unless options.any?

        check_insert_and_update_arguments(options)

        return false if callback(:before_update) == false
        insert_with_timestamps(false)

        #set the command to update unless specified
        #remove the duplicate_update_key if any
        sql_options = options.dup
        sql_options[:command]||='UPDATE'
        sql_options.delete(:on_duplicate_key_update)

        quoted_attributes = attributes_with_quotes(false, false, attribute_names)
        return 0 if quoted_attributes.empty?

        locking_sql = update_locking_sql

        sql = self.class.construct_ar_extension_sql(sql_options) do |sql, o|
          sql << "#{self.class.quoted_table_name} "
          sql << "SET #{quoted_comma_pair_list(connection, quoted_attributes)} " +
            "WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quote_value(id)}"
          sql << locking_sql if locking_sql
        end


        reloaded = false

        begin
          affected_rows = connection.update(sql,
            "#{self.class.name} Update X #{'With optimistic locking' if locking_sql} ")
          #raise exception if optimistic locking is enabled and no rows were updated
          raise ActiveRecord::StaleObjectError, "#{affected_rows} Attempted to update a stale object" if locking_sql && affected_rows != 1
          @stale_record = (affected_rows == 0)
          callback(:after_update)

          #catch the duplicate error and update the existing record
        rescue Exception => e
          if (duplicate_columns(options) && options[:on_duplicate_key_update] &&
                connection.respond_to?('duplicate_key_update_error?') &&
                connection.duplicate_key_update_error?(e))
            update_existing_record(options)
            reloaded = true
          else
            raise e
          end

        end

        load_duplicate_record(options) if options[:reload] && !reloaded

        return true
      end

      # Creates a new record with values matching those of the instance attributes.
      def create_with_extension(options={})#:nodoc:
        return create_without_extension unless options.any?

        check_insert_and_update_arguments(options)

        return 0 if callback(:before_create) == false
        insert_with_timestamps(true)

        if self.id.nil? && connection.prefetch_primary_key?(self.class.table_name)
          self.id = connection.next_sequence_value(self.class.sequence_name)

        end

        quoted_attributes = attributes_with_quotes

        statement = if quoted_attributes.empty?
          connection.empty_insert_statement(self.class.table_name)
        else
          options[:command]||='INSERT'
          sql = self.class.construct_ar_extension_sql(options) do |sql, options|
            sql << "INTO #{self.class.table_name} (#{quoted_column_names.join(', ')}) "
            sql << "VALUES(#{attributes_with_quotes.values.join(', ')})"
          end
        end

        self.id = connection.insert(statement, "#{self.class.name} Create X",
          self.class.primary_key, self.id, self.class.sequence_name)


        @new_record = false

        #most adapters update the insert id number even if nothing was
        #inserted. Reset to 0 for all :on_duplicate_key_update
        self.id = 0 if options[:on_duplicate_key_update]


        #the record was not created. Set the value to stale
        if self.id == 0
          @stale_record = true
          load_duplicate_record(options) if options[:reload]
        end

        callback(:after_create)

        self.id
      end

      # Replace deletes the existing duplicate if one exists and then
      # inserts the new record. Foreign keys are updated only if
      # performed by the database.
      #
      # The +options+ hash accepts the following attributes:
      # * <tt>:pre_sql</tt> - sql that appears before the query
      # * <tt>:post_sql</tt> - sql that appears after the query
      # * <tt>:keywords</tt> - text that appears after the 'REPLACE' command
      #
      # ==== Examples
      # Replace a single object
      #   user.replace

      def replace(options={})
        options.assert_valid_keys(:pre_sql, :post_sql, :keywords)
        create_with_extension(options.merge(:command => 'REPLACE'))
      end

      # Returns true if the record data is stale
      # This can occur when creating or updating a record with
      # options <tt>:on_duplicate_key_update</tt> or <tt>:ignore</tt>
      # without reloading(<tt> :reload  => true</tt>)
      #
      # In other words, the attributes of a stale record may not reflect those
      # in the database
      def stale_record?; @stale_record.is_a?(TrueClass); end

      # Reload Duplicate records like +reload_duplicate+ but
      # throw an exception if no duplicate record is found
      def reload_duplicate!(options={})
        options.assert_valid_keys(:duplicate_columns, :force, :delete)
        raise NoDuplicateFound.new("Record is not stale") if !stale_record? and !options[:force].is_a?(TrueClass)
        load_duplicate_record(options.merge(:reload => true))
      end

      # Reload the record's duplicate based on the
      # the duplicate_columns. Returns true if the reload was successful.
      # <tt>:duplicate_columns</tt> - the columns to search on
      # <tt>:force</tt> - force a reload even if the record is not stale
      # <tt>:delete</tt> - delete the existing record if there is one. Defaults to true
      def reload_duplicate(options={})
        reload_duplicate!(options)
      rescue NoDuplicateFound => e
        return false
      end
      protected

      # Returns the list of fields for which there is a unique key.
      # When reloading duplicates during updates, with the <tt> :reload => true </tt>
      # the reloaded existing duplicate record is the one matching the attributes specified
      # by +duplicate_columns+.
      #
      # This data can either be passed into the save command, or the
      # +duplicate_columns+ method can be overridden in the
      # ActiveRecord subclass to return the columns with a unique key
      #
      # ===Example
      # User has a unique key on name. If a user exists already
      # the user object will be replaced by the existing user
      #   user.name = 'blythe'
      #   user.save(:ignore => true, :duplicate_columns => 'name', :reload => true)
      #
      # Alternatively, the User class can be overridden
      #   class User
      #     protected
      #       def duplicate_columns(options={}); [:name]; end
      #   end
      #
      # Then, the <tt>:duplicate_columns</tt> field is not needed during save
      #   user.update(:on_duplicate_key_update => [:password, :updated_at], :reload => true)
      #

      def duplicate_columns(options={})
        options[:duplicate_columns]
      end

      #update timestamps
      def insert_with_timestamps(bCreate=true)#:nodoc:
        if record_timestamps
          t = ( self.class.default_timezone == :utc ? Time.now.utc : Time.now )
          write_attribute('created_at', t) if bCreate && respond_to?(:created_at) && created_at.nil?
          write_attribute('created_on', t) if bCreate && respond_to?(:created_on) && created_on.nil?

          write_attribute('updated_at', t) if respond_to?(:updated_at)
          write_attribute('updated_on', t) if respond_to?(:updated_on)
        end
      end

      # Update the optimistic locking column and
      # return the sql necessary. update_with_lock is not called
      # since update_x is aliased to update
      def update_locking_sql()#:nodoc:
        if locking_enabled?
          lock_col = self.class.locking_column
          previous_value = send(lock_col)
          send(lock_col + '=', previous_value + 1)
          " AND #{self.class.quoted_locking_column} = #{quote_value(previous_value)}"
        else
          nil
        end
      end


      def duplicate_option_check?(options)#:nodoc:
        options.has_key?(:on_duplicate_key_update) ||
          options[:keywords].to_s.downcase == 'ignore' ||
          options[:ignore]
      end

      #Update the existing record with the new data from the duplicate column fields
      #automatically delete and reload the object
      def update_existing_record(options)#:nodoc:
        load_duplicate_record(options.merge(:reload => true)) do |record|
          updated_attributes = options[:on_duplicate_key_update].inject({}) {|map, attribute| map[attribute] = self.send(attribute); map}
          record.update_attributes(updated_attributes)
        end
      end

      #reload the record's duplicate based on the
      #the duplicate_columns parameter or overwritten function
      def load_duplicate_record(options, &block)#:nodoc:

        search_columns = duplicate_columns(options)

        #search for the existing columns
        conditions = search_columns.inject([[],{}]){|sql, field|
          sql[0] << "#{field} = :#{field}"
          sql[1][field] = send(field)
          sql
        }

        conditions[0] = conditions[0].join(' and ')

        record = self.class.find :first, :conditions => conditions

        raise NoDuplicateFound.new("Cannot find duplicate record.") if record.nil?

        yield record if block

        @stale_record = true

        if options[:reload]
          #do not delete new records, the same record or
          #if user specified not to delete
          if self.id.to_i > 0 && self.id != record.id && !options[:delete].is_a?(FalseClass)
            self.class.delete_all(['id = ?', self.id])
          end
          reset_to_record(record)
        end
        true
      end
      #reload this object to the specified record
      def reset_to_record(record)#:nodoc:
        self.id = record.id
        self.reload
        @stale_record = false
      end

      #assert valid options
      #ensure that duplicate_columns are specified with reload
      def check_insert_and_update_arguments(options)#:nodoc:
        options.assert_valid_keys([:on_duplicate_key_update, :reload, :command, :ignore, :pre_sql, :post_sql, :keywords, :duplicate_columns])
        if duplicate_columns(options).blank? && duplicate_option_check?(options) && options[:reload]
          raise(ArgumentError, "Unknown key: on_duplicate_key_update is not supported for updates without :duplicate_columns")
        end
      end
    end
  end
end
