# ActiveRecord::Extensions::FinderOptions provides additional functionality to the ActiveRecord
# ORM library created by DHH for Rails.
#
# == Using finder_sql_to_string
# Expose the finder sql to a string. The options are identical to those accepted by <tt>find(:all, options)</tt>
# the find method takes. 
# === Example:
#   sql = Contact.finder_sql_to_string(:include => :primary_email_address)
#   Contact.find_by_sql(sql + 'USE_INDEX(blah)')
#
# == Enhanced Finder Options
# Add index hints, keywords, and pre and post SQL to the query without writing direct SQL
# === Parameter options:
# * <tt>:pre_sql</tt> appends SQL after the SELECT and before the selected columns
#
#  sql = Contact.find :first, :pre_sql => "HIGH_PRIORITY", :select => 'contacts.name', :conditions => 'id = 5'
#  SQL> SELECT HIGH_PRIORITY contacts.name FROM `contacts` WHERE id = 5
#
# * <tt>:post_sql</tt> appends additional SQL to the end of the statement
#  Contact.find :first, :post_sql => 'FOR UPDATE', :select => 'contacts.name', :conditions => 'id = 5'
#  SQL> SELECT contacts.name FROM `contacts` where id == 5 FOR UPDATE
#
#  Book.find :all, :post_sql => 'USE_INDEX(blah)'
#  SQL> SELECT books.* FROM `books` USE_INDEX(blah)
#
# * <tt>:override_select</tt> is used to override the <tt>SELECT</tt> clause of eager loaded associations
# The <tt>:select</tt> option is ignored by the vanilla ActiveRecord when using eager loading with associations (when <tt>:include</tt> is used)
# (refer to http://dev.rubyonrails.org/ticket/5371)
# The <tt>:override_select</tt> options allows us to directly specify a <tt>SELECT</tt> clause without affecting the operations of legacy code  (ignore <tt>:select</tt>)
# of the current code. Several plugins are available that enable select with eager loading
# Several plugins exist to force <tt>:select</tt> to work with eager loading.
#
# <tt>script/plugin install http://arperftoolkit.rubyforge.org/svn/trunk/eload_select/ </tt>
#    
# * <tt>:having</tt> only works when <tt>:group</tt> option is specified
#  Book.find(:all, :select => 'count(*) as count_all, topic_id', :group => :topic_id, :having => 'count(*) > 1')
#  SQL>SELECT count(*) as count_all, topic_id FROM `books`  GROUP BY topic_id HAVING count(*) > 1
#
# == Developers
# * Blythe Dunham http://blythedunham.com
#
# == Homepage
# * Project Site: http://www.continuousthinking.com/tags/arext
# * Rubyforge Project: http://rubyforge.org/projects/arext
# * Anonymous SVN: svn checkout svn://rubyforge.org/var/svn/arext
#

module ActiveRecord::Extensions::FinderOptions
  def self.included(base) 
    
    #alias and include only if not yet defined
    unless base.respond_to?(:construct_finder_sql_ext)
      base.extend ClassMethods
      base.class_eval do
        class << self
          VALID_FIND_OPTIONS.concat([:pre_sql, :post_sql, :keywords, :ignore, :rollup, :override_select, :having])
          alias_method              :construct_finder_sql, :construct_finder_sql_ext
          alias_method_chain        :construct_finder_sql_with_included_associations, :ext
        end
      end
   end
  end
  
  module ClassMethods
    # Return a string containing the SQL used with the find(:all)
    # The options are the same as those with find(:all)
    # 
    #   sql = Contact.finder_sql_to_string(:include => :primary_email_address)
    #   Contact.find_by_sql(sql + 'USE_INDEX(blah)')
    def finder_sql_to_string(options)      
      include_associations = merge_includes(scope(:find, :include), options[:include])
      select_sql = self.send( (include_associations.any? && references_eager_loaded_tables?(options)) ?
        :finder_sql_with_included_associations :
        :construct_finder_sql, options)
        
      select_sql.strip
    end
            
    protected
    
    # construct_finder_sql is called when not using eager loading (:include option is NOT specified)
    def construct_finder_sql_ext(options) # :nodoc:
      
      #add piggy back option if plugin is installed
      add_piggy_back!(options) if self.respond_to? :add_piggy_back!

      scope = scope(:find)
      sql = pre_sql_statements(options)
      sql  << "#{options[:select] || options[:override_select] || (scope && scope[:select]) || default_select(options[:joins] || (scope && scope[:joins]))} "
      sql << "FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "

      add_joins!(sql, options[:joins], scope)
      add_conditions!(sql, options[:conditions], scope)

      add_group!(sql, options[:group], scope)
      add_having!(sql, options, scope)
      add_order!(sql, options[:order], scope)
      add_limit!(sql, options, scope)
      add_lock!(sql, options, scope)
      
      sql << post_sql_statements(options)
      sql

    end 

    #override the constructor for use with associations (:include option)
    #directly use eager select if that plugin is loaded instead of this one
    def construct_finder_sql_with_included_associations_with_ext(options, join_dependency)#:nodoc
      if respond_to?(:construct_finder_sql_with_included_associations_with_eager_select) 
        return construct_finder_sql_with_included_associations_with_eager_select(options, join_dependency)
      else
        scope = scope(:find)
        sql = pre_sql_statements(options)
        sql << "#{options[:override_select]||column_aliases(join_dependency)} FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "
        sql << join_dependency.join_associations.collect{|join| join.association_join }.join
        
        
        add_joins!(sql, options[:joins], scope)
        add_conditions!(sql, options[:conditions], scope)
        add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        add_group!(sql, options[:group], scope)
        add_having!(sql, options, scope)
        add_order!(sql, options[:order], scope)
        add_limit!(sql, options, scope) if using_limitable_reflections?(join_dependency.reflections)
        add_lock!(sql, options, scope)

        sql << post_sql_statements(options)

        return sanitize_sql(sql)
      end
    end

    #generate the finder sql for use with associations (:include => :something)
    def finder_sql_with_included_associations(options = {})#:nodoc
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merge_includes(scope(:find, :include), options[:include]), options[:joins])
      sql = construct_finder_sql_with_included_associations_with_ext(options, join_dependency)
    end
      
    def post_sql_statements(options)#:nodoc
      connection.post_sql_statements(quoted_table_name, options).join(' ')
    end
    
    def pre_sql_statements(options)#:nodoc
      connection.pre_sql_statements({:command => 'SELECT'}.merge(options)).join(' ').strip + " "
    end
    
    def add_having!(sql, options, scope = :auto)#:nodoc
      sql << " HAVING #{options[:having]} " if options[:group] && options[:having]
    end
    
  end
end
