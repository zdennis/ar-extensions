module ActiveRecord::Extensions::Union#:nodoc:
  module UnionSupport #:nodoc:
    def supports_union? #:nodoc:
      true
    end
  end
end

class ActiveRecord::Base
  supports_extension :union

  extend ActiveRecord::Extensions::SqlGeneration
  class << self
    # Find a union of two or more queries
    # === Args
    # Each argument is a hash map of options sent to <tt>:find :all</tt>
    # including <tt>:conditions</tt>, <tt>:join</tt>, <tt>:group</tt>,
    # <tt>:having</tt>, and <tt>:limit</tt>
    #
    # In addition the following options are accepted
    # * <tt>:pre_sql</tt> inserts SQL before the SELECT statement of this protion of the +union+
    # * <tt>:post_sql</tt> appends additional SQL to the end of the statement
    # * <tt>:override_select</tt> is used to override the <tt>SELECT</tt> clause of eager loaded associations
    #
    # == Examples
    # Find the union of a San Fran zipcode with a Seattle zipcode
    #    union_args1 = {:conditions => ['zip_id = ?', 94010], :select => :phone_number_id}
    #    union_args2 = {:conditions => ['zip_id = ?', 98102], :select => :phone_number_id}
    #    Contact.find_union(union_args1, union_args2, ...)
    #
    #    SQL>  (SELECT phone_number_id FROM contacts WHERE zip_id = 94010) UNION
    #          (SELECT phone_number_id FROM contacts WHERE zip_id = 98102) UNION ...
    #
    # == Global Options
    # To specify global options that apply to the entire union, specify a hash as the
    # first parameter with a key <tt>:union_options</tt>. Valid options include
    # <tt>:group</tt>, <tt>:having</tt>, <tt>:order</tt>, and <tt>:limit</tt>
    #
    #
    # Example:
    #  Contact.find_union(:union_options => {:limit => 10, :order => 'created_on'},
    #  union_args1, union_args2, ...)
    #
    #  SQL> ((select phone_number_id from contacts ...) UNION (select phone_number_id from contacts ...)) order by created_on limit 10
    #
    def find_union(*args)
      supports_union!
      find_by_sql(find_union_sql(*args))
    end

    # Count across a union of two or more queries
    # === Args
    # * +column_name+ - The column to count. Defaults to all ('*')
    # * <tt>*args</tt> - Each additional argument is a hash map of options used by <tt>:find :all</tt>
    # including <tt>:conditions</tt>, <tt>:join</tt>, <tt>:group</tt>,
    # <tt>:having</tt>, and <tt>:limit</tt>
    #
    # In addition the following options are accepted
    # * <tt>:pre_sql</tt> inserts SQL before the SELECT statement of this protion of the +union+
    # * <tt>:post_sql</tt> appends additional SQL to the end of the statement
    # * <tt>:override_select</tt> is used to override the <tt>SELECT</tt> clause of eager loaded associations
    #
    # Note that distinct is implied so a record that matches more than one
    # portion of the union is counted only once.
    #
    # == Global Options
    # To specify global options that apply to the entire union, specify a hash as the
    # first parameter with a key <tt>:union_options</tt>. Valid options include
    # <tt>:group</tt>, <tt>:having</tt>, <tt>:order</tt>, and <tt>:limit</tt>
    #
    # == Examples
    # Count the number of people who live in Seattle and San Francisco
    #  Contact.count_union(:phone_number_id,
    #        {:conditions => ['zip_id = ?, 94010]'},
    #        {:conditions => ['zip_id = ?', 98102]})
    #  SQL> select count(*) from ((select phone_number_id from contacts ...) UNION (select phone_number_id from contacts ...)) as counter_tbl;
    def count_union(column_name, *args)
      supports_union!
      count_val = calculate_union(:count, column_name, *args)
      (args.length == 1 && args.first[:limit] && args.first[:limit].to_i < count_val) ? args.first[:limit].to_i : count_val
    end

    protected

    #do a union of specified calculation. Only for simple calculations
    def calculate_union(operation, column_name, *args)#:nodoc:
      union_options = remove_union_options(args)


      if args.length == 1
        column_name     = '*' if column_name == :all
        calculate(operation, column_name, args.first.update(union_options))

      # For more than one map of options, count off the subquery of all the column_name fields unioned together
      # For example, if column_name is phone_number_id the generated query is
      #  Contact.calculate_union(:count, :phone_number_id, args)
      #  SQL> select count(*) from
      #     ((select phone_number_id from contacts ...)
      #      UNION
      #     (select phone_number_id from contacts ...)) as counter_tbl
      else
        column_name     = primary_key if column_name == :all
        column          = column_for column_name
        column_name     = "#{table_name}.#{column_name}" unless column_name.to_s.include?('.')

        group_by = union_options.delete(:group)
        having = union_options.delete(:having)
        query_alias = union_options.delete(:query_alias)||"#{operation}_giraffe"


        #aggregate_alias should be table_name_id
        aggregate_alias = column_alias_for('', column_name)
        #main alias is operation_table_name_id
        main_aggregate_alias = column_alias_for(operation, column_name)

        sql = "SELECT "
        sql << (group_by ? "#{group_by}, #{operation}(#{aggregate_alias})" : "#{operation}(*)")
        sql << " AS #{main_aggregate_alias}"
        sql << " FROM ("

        #by nature of the union the results will always be distinct, so remove distinct column here
        sql << args.inject([]){|l, a|
          calc = "(#{construct_calculation_sql_with_extension('', column_name, a)})"
          #for group by we need to select the group by column also
          calc.gsub!(" AS #{aggregate_alias}", " AS #{aggregate_alias}, #{group_by} ") if group_by
          l <<  calc
        }.join(" UNION ")

        add_union_options!(sql, union_options)

        sql << ") as #{query_alias}"

        if group_by
          #add groupings
          sql << " GROUP BY #{group_by}"
          sql << " HAVING #{having}" if having

          calculated_data = connection.select_all(sql)

          calculated_data.inject(ActiveSupport::OrderedHash.new) do |all, row|
            key   = type_cast_calculated_value(row[group_by], column_for(group_by.to_s))
            value = row[main_aggregate_alias]
            all << [key, type_cast_calculated_value(value, column_for(column), operation)]
          end

        else
          count_by_sql(sql)
        end
      end
    end


    #Add Global Union options
    def add_union_options!(sql, options)#:nodoc:
      sql << " GROUP BY #{options[:group]} " if options[:group]

      if options[:order] || options[:limit]
        scope = scope(:find)
        add_order!(sql, options[:order], scope)
        add_limit!(sql, options, scope)
      end
      sql
    end

    #Remove the global union options
    def remove_union_options(args)#:nodoc:
      args.first.is_a?(Hash) && args.first.has_key?(:union_options)  ? (args.shift)[:union_options] : {}
    end

    def construct_calculation_sql_with_extension(operation, column_name, options)
      construct_ar_extension_sql(options.merge(:command => '', :keywords => nil, :distinct => nil)) {|sql, o|
        calc_sql = construct_calculation_sql(operation, column_name, options)

        #this is really gross but prevents us from rewriting construct_calculation_sql
        calc_sql.gsub!(/^SELECT\s/, "SELECT #{options[:keywords]} ") if options[:keywords]

        sql << calc_sql
      }
    end

    # Return the sql for union of the query options specified on the command line
    # If the first parameter is a map containing :union_options, use these
    def find_union_sql(*args)#:nodoc:
      options = remove_union_options(args)

      if args.length == 1
        return finder_sql_to_string(args.first.update(options))
      end

      sql = args.inject([]) do |sql_list, union_args|
        part = union_args.merge(:force_eager_load => true,
                                :override_select => union_args[:select]||"#{quoted_table_name}.*",
                                :select => nil)
        sql_list << "(#{finder_sql_to_string(part)})"
        sql_list
      end.join(" UNION ")


      add_union_options!(sql, options)
      sql
    end
  end
end

