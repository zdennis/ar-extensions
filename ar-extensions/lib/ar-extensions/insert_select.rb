# Insert records in bulk with a select statement
#
# == Parameters
# * +options+ - the options used for the finder sql (select)
#
# === Options
# Any valid finder options (options for <tt>ActiveRecord::Base.find(:all)</tt> )such as <tt>:joins</tt>, <tt>:conditions</tt>, <tt>:include</tt>, etc including:
# * <tt>:from</tt> - the symbol, class name or class used for the finder SQL (select)
# * <tt>:on_duplicate_key_update</tt> - an array of fields to update, or a custom string
# * <tt>:select</tt> - An array of fields to select or custom string. The SQL will be sanitized and ? replaced with values as with <tt>:conditions</tt>.
# * <tt>:ignore => true </tt> - will ignore any duplicates 
# * <tt>:into</tt> - Specifies the columns for which data will be inserted. An array of fields to select or custom string.
#
# == Examples
# Create cart items for all books for shopping cart <tt>@cart+
# setting the +copies+ field to 1, the +updated_at+ field to Time.now and the +created_at+ field to the database function now()
#  CartItem.insert_select(:from => :book,
#                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now], 
#                         :into => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]})
#                         
# GENERATED SQL example (MySQL): 
#  INSERT INTO `cart_items` ( `book_id`, `shopping_cart_id`, `copies`, `updated_at`, `created_at` ) 
#  SELECT books.id, '134', 1, '2009-03-02 18:28:25', now() FROM `books`
#
# A similar example that 
# * uses the class +Book+ instead of symbol <tt>:book</tt>
# * a custom string (instead of an Array) for the <tt>:select</tt> of the +insert_options+
# * Updates the +updated_at+ field of all existing cart item. This assumes there is a unique composite index on the +book_id+ and +shopping_cart_id+ fields
#
#  CartItem.insert_select(:from => Book,
#                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now], 
#                         :into => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
#                         :on_duplicate_key_update => [:updated_at]) 
# GENERATED SQL example (MySQL):   
#    INSERT INTO `cart_items` ( cart_items.book_id, shopping_cart_id, copies, updated_at, created_at ) 
#    SELECT books.id, '138', 1, '2009-03-02 18:32:34', now() FROM `books` 
#           ON DUPLICATE KEY UPDATE `cart_items`.`updated_at`=VALUES(`updated_at`)
#
#
# Similar example ignoring duplicates
#  CartItem.insert_select(:from => :book,
#                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now], 
#                         :into => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at],
#                         :ignore => true)
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

module ActiveRecord::Extensions::InsertSelectSupport #:nodoc:
  def supports_insert_select? #:nodoc:
    true
  end
end

class ActiveRecord::Base
  
  include ActiveRecord::Extensions::SqlGeneration

  class << self
    # Insert records in bulk with a select statement
    #
    # == Parameters
    # * +options+ - the options used for the finder sql (select)
    #
    # === Options
    # Any valid finder options (options for <tt>ActiveRecord::Base.find(:all)</tt> )such as <tt>:joins</tt>, <tt>:conditions</tt>, <tt>:include</tt>, etc including:
    # * <tt>:from</tt> - the symbol, class name or class used for the finder SQL (select)
    # * <tt>:on_duplicate_key_update</tt> - an array of fields to update, or a custom string
    # * <tt>:select</tt> - An array of fields to select or custom string. The SQL will be sanitized and ? replaced with values as with <tt>:conditions</tt>.
    # * <tt>:ignore => true </tt> - will ignore any duplicates
    # * <tt>:into</tt> - Specifies the columns for which data will be inserted. An array of fields to select or custom string.
    #
    # == Examples
    # Create cart items for all books for shopping cart <tt>@cart+
    # setting the +copies+ field to 1, the +updated_at+ field to Time.now and the +created_at+ field to the database function now()
    #  CartItem.insert_select(:from => :book,
    #                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now],
    #                         :into => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]})
    #
    # GENERATED SQL example (MySQL):
    #  INSERT INTO `cart_items` ( `book_id`, `shopping_cart_id`, `copies`, `updated_at`, `created_at` )
    #  SELECT books.id, '134', 1, '2009-03-02 18:28:25', now() FROM `books`
    #
    # A similar example that
    # * uses the class +Book+ instead of symbol <tt>:book</tt>
    # * a custom string (instead of an Array) for the <tt>:select</tt> of the +insert_options+
    # * Updates the +updated_at+ field of all existing cart item. This assumes there is a unique composite index on the +book_id+ and +shopping_cart_id+ fields
    #
    #  CartItem.insert_select(:from => Book,
    #                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now],
    #                         :into => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
    #                         :on_duplicate_key_update => [:updated_at])
    # GENERATED SQL example (MySQL):
    #    INSERT INTO `cart_items` ( cart_items.book_id, shopping_cart_id, copies, updated_at, created_at )
    #    SELECT books.id, '138', 1, '2009-03-02 18:32:34', now() FROM `books`
    #           ON DUPLICATE KEY UPDATE `cart_items`.`updated_at`=VALUES(`updated_at`)
    #
    #
    # Similar example ignoring duplicates
    #  CartItem.insert_select(:from => :book,
    #                         :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now],
    #                         :into => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at],
    #                         :ignore => true)
    def insert_select(options={})
      select_obj = options.delete(:from).to_s.classify.constantize
      #TODO: add batch support for high volume inserts
      #return insert_select_batch(select_obj, select_options, insert_options) if insert_options[:batch]
      sql = construct_insert_select_sql(select_obj, options)
      connection.insert(sql, "#{name} Insert Select #{select_obj}")
    end

    protected

    def construct_insert_select_sql(select_obj, options)#:nodoc:
      construct_ar_extension_sql(gather_insert_options(options), valid_insert_select_options) do |sql, into_op|
        sql << " INTO #{quoted_table_name} "
        sql << "( #{into_column_sql(options.delete(:into))} ) "
        
        #sanitize the select sql based on the select object
        sql << select_obj.send(:finder_sql_to_string, sanitize_select_options(options))
        sql
      end
    end
    
    #  return a list of the column names quoted accordingly
    #  nil => All columns except primary key (auto update)
    #  String => Exact String
    #  Array
    #    needs sanitation ["?, ?", 5, 'test'] => "5, 'test'"  or [":date", {:date => Date.today}] => "12-30-2006"]
    #    list of strings or symbols returns quoted values [:start, :name] => `start`, `name` or ['abc'] => `start`
    def select_column_sql(field_list=nil)#:nodoc:
      if field_list.kind_of?(String)
        field_list.dup
      elsif ((field_list.kind_of?(Array) && field_list.first.is_a?(String)) &&
             (field_list.last.is_a?(Hash) || field_list.first.include?('?')))
        sanitize_sql(field_list)
      else
        field_list = field_list.blank? ? self.column_names - [self.primary_key] : [field_list].flatten
        field_list.collect{|field| self.connection.quote_column_name(field.to_s) }.join(", ")
      end
    end

    alias_method :into_column_sql, :select_column_sql
    
    #sanitize the select options for insert select
    def sanitize_select_options(options)#:nodoc:
      o = options.dup
      select = o.delete :select
      o[:override_select] = select ? select_column_sql(select) : ' * '
      o
    end


    def valid_insert_select_options#:nodoc:
      @@valid_insert_select_options ||= [:command, :into_pre, :into_post, 
                                         :into_keywords, :ignore,
                                         :on_duplicate_key_update]
    end

    #move all the insert options to a seperate map
    def gather_insert_options(options)#:nodoc:
      into_options = valid_insert_select_options.inject(:command => 'INSERT') do |map, o|
        v = options.delete(o)
        map[o] =  v if v
        map
      end
    end

  end
end
