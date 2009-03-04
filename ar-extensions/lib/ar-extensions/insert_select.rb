# Insert records in bulk with a select statement
#
# == Parameters
# * +select_obj_name+ - the symbol, class name or class used for the finder SQL (select)
# * +select_options+ - the options used for the finder sql (select)
# * +insert_options+ - the options used for the insert (insert)
#
# === Select Options
# Any valid finder options (options for <tt>ActiveRecord::Base.find(:all)</tt> )such as <tt>:joins</tt>, <tt>:conditions</tt>, <tt>:include</tt>, etc including:
# * <tt>:on_duplicate_key_update</tt> - an array of fields to update, or a custom string
# * <tt>:select</tt> - An array of fields to select or custom string. The SQL will be sanitized and ? replaced with values as with <tt>:conditions</tt>.
# * <tt>:ignore => true </tt> - will ignore any duplicates 
#
# === Insert Options
# * <tt>:select</tt> - Specifies the columns for which data will be inserted. An array of fields to select or custom string. 
#
# == Examples
# Create cart items for all books for shopping cart <tt>@cart+
# setting the +copies+ field to 1, the +updated_at+ field to Time.now and the +created_at+ field to the database function now()
#  CartItem.insert_select(:book, 
#                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
#                         {:select => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]})
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
#  CartItem.insert_select(Book, 
#                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
#                          :select => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
#                           :on_duplicate_key_update => [:updated_at]) 
# GENERATED SQL example (MySQL):   
#    INSERT INTO `cart_items` ( cart_items.book_id, shopping_cart_id, copies, updated_at, created_at ) 
#    SELECT books.id, '138', 1, '2009-03-02 18:32:34', now() FROM `books` 
#           ON DUPLICATE KEY UPDATE `cart_items`.`updated_at`=VALUES(`updated_at`)
#
#
# Similar example ignoring duplicates
#  CartItem.insert_select(:book, 
#                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
#                         {:select => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at], :ignore => true})
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
  class << self
    # Insert records in bulk with a select statement
    #
    # == Parameters
    # * +select_obj_name+ - the symbol, class name or class used for the finder SQL (select)
    # * +select_options+ - the options used for the finder sql (select)
    # * +insert_options+ - the options used for the insert (insert)
    #
    # === Select Options
    # Any valid finder options (options for <tt>ActiveRecord::Base.find(:all)</tt> )such as <tt>:joins</tt>, <tt>:conditions</tt>, <tt>:include</tt>, etc including:
    # * <tt>:on_duplicate_key_update</tt> - an array of fields to update, or a custom string
    # * <tt>:select</tt> - An array of fields to select or custom string. The SQL will be sanitized and ? replaced with values as with <tt>:conditions</tt>.
    # * <tt>:ignore => true </tt> - will ignore any duplicates 
    #
    # === Insert Options
    # * <tt>:select</tt> - Specifies the columns for which data will be inserted. An array of fields to select or custom string. 
    #
    # == Examples
    # Create cart items for all books for shopping cart <tt>@cart+
    # setting the +copies+ field to 1, the +updated_at+ field to Time.now and the +created_at+ field to the database function now()
    #  CartItem.insert_select(:book, 
    #                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
    #                         {:select => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]})
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
    #  CartItem.insert_select(Book, 
    #                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
    #                          :select => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
    #                           :on_duplicate_key_update => [:updated_at]) 
    # GENERATED SQL example (MySQL):   
    #    INSERT INTO `cart_items` ( cart_items.book_id, shopping_cart_id, copies, updated_at, created_at ) 
    #    SELECT books.id, '138', 1, '2009-03-02 18:32:34', now() FROM `books` 
    #           ON DUPLICATE KEY UPDATE `cart_items`.`updated_at`=VALUES(`updated_at`)
    #
    #
    # Similar example ignoring duplicates
    #  CartItem.insert_select(:book, 
    #                         {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
    #                         {:select => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at], :ignore => true})
    def insert_select(select_obj_name, select_options, insert_options={})
      select_obj = select_obj_name.to_s.classify.constantize
      #TODO: add batch support for high volume inserts
      #return insert_select_batch(select_obj, select_options, insert_options) if insert_options[:batch]
      sql = construct_insert_select_sql(select_obj, select_options, insert_options)
      connection.insert(sql, "#{name} Insert Select #{select_obj}")
    end

    protected
    #Base sql method for constructing inserts, updates
    def construct_insert_sql(options={}, valid_options = [], &block)#:nodoc:
      options.assert_valid_keys(:keywords, :command, :on_duplicate_key_update, :post_sql, :pre_sql, :select, :rollup, :ignore, *valid_options)
      sql = connection.pre_sql_statements(options).join(' ')
      yield sql, options
      sql << connection.post_sql_statements(quoted_table_name, options).join(' ')
      sql
    end

    def construct_insert_select_sql(select_obj, select_options, insert_options={})#:nodoc:
      insert_sql = construct_insert_sql({:command => 'INSERT'}.merge(insert_options)) do |sql, options|
        sql << " INTO #{quoted_table_name} "
        sql << "( #{select_columns(insert_options[:select])} ) "

        #sanitize the select sql based on the select object 
        sql << select_obj.send(:finder_sql_to_string, sanitize_select_options(select_options))
      end
      insert_sql
    end
    
    #  return a list of the column names quoted accordingly
    #  nil => All columns except primary key (auto update)
    #  String => Exact String
    #  Array
    #    needs sanitation ["?, ?", 5, 'test'] => "5, 'test'"  or [":date", {:date => Date.today}] => "12-30-2006"]
    #    list of strings or symbols returns quoted values [:start, :name] => `start`, `name` or ['abc'] => `start`
    def select_columns(field_list=nil)#:nodoc:
      if field_list.kind_of?(String)
        field_list
      elsif field_list.kind_of?(Array) && field_list.first.is_a?(String) && (field_list.last.is_a?(Hash) || field_list.first.include?('?'))
        s = sanitize_sql(field_list)
        s
      else
        field_list = field_list.blank? ? self.column_names - [self.primary_key] : [field_list].flatten
        field_list.collect{|field| self.connection.quote_column_name(field.to_s) }.join(", ")
      end
    end
   
    #sanitize the select options for insert select
    def sanitize_select_options(options)#:nodoc:
      o = options.dup
      select = o.delete :select
      o[:override_select] = select ? select_columns(select) : ' * '
      o
    end
  end
end
