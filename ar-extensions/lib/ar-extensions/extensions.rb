require 'forwardable'

# ActiveRecord::Extensions provides additional functionality to the ActiveRecord
# ORM library created by DHH for Rails.
#
# It's main features include: 
# * better finder support using a :conditions Hash for ActiveRecord::Base#find 
# * better finder support using any object that responds to the to_sql method
# * mass data import functionality
# * a more modular design to extending ActiveRecord
#
#
# == Using Better Finder Hash Support
# Here are a few examples, please refer to the class documentation for each 
# extensions:
#  
#  class Post < ActiveRecord::Base ; end
#  
#  Post.find( :all, :conditions=>{ 
#    :title => "Title",                           # title='Title'
#    :author_contains => "Zach",                  # author like '%Zach%'
#    :author_starts_with => "Zach",               # author like 'Zach%'
#    :author_ends_with => "Dennis",               # author like '%Zach'
#    :published_at => (Date.now-30 .. Date.now),  # published_at BETWEEN xxx AND xxx
#    :rating => [ 4, 5, 6 ],                      # rating IN ( 4, 5, 6 )
#    :rating_not_in => [ 7, 8, 9 ]                # rating NOT IN( 4, 5, 6 )
#    :rating_ne => 4,                             # rating != 4
#    :rating_gt => 4,                             # rating > 4
#    :rating_lt => 4,                             # rating < 4
#    :content => /(a|b|c)/                        # REGEXP '(a|b|c)'
#  )
#
#
# == Create Your Own Finder Extension Example
# The following example shows you how-to create a robust and reliable
# finder extension which allows you to use Ranges in your :conditions Hash. This
# is the actual implementation in ActiveRecord::Extensions.
#
#  class RangeExt 
#    NOT_IN_RGX = /^(.+)_(ne|not|not_in|not_between)$/
#    
#    def self.process( key, val, caller )
#      return nil unless val.is_a?( Range )
#      match_data = key.to_s.match( NOT_IN_RGX )
#      key = match_data.captures[0] if match_data
#      fieldname = caller.connection.quote_column_name( key )
#      min = caller.connection.quote( val.first, caller.columns_hash[ key ] )
#      max = caller.connection.quote( val.last, caller.columns_hash[ key ] )
#      str = "#{caller.table_name}.#{fieldname} #{match_data ? 'NOT ' : '' } BETWEEN #{min} AND #{max}"
#      Result.new( str, nil )
#   end
#
#
# == Using to_sql Ducks In Your Find Methods!
# The below example shows you how-to utilize objects that respond_to the method +to_sql+ in
# your finds:
#
#  class InsuranceClaim < ActiveRecord::Base ; end
#  
#  class InsuranceClaimAgeAndTypeQuery
#    def to_sql
#       "age_in_days BETWEEN 1 AND 60 AND claim_type IN( 'typea', 'typeb' )"
#    end
#  end
#  
#  claims = InsuranceClaim.find( :all, InsuranceClaimAgeAndTypeQuery.new )
#  
#  claims = InsuranceClaim.find( :all, :conditions=>{
#    :claim_amount_gt => 30000,
#    :age_and_type => InsuranceClaimAgeAndTypeQuery.new } 
#  )
# 
# == Importing Lots of Data
#
# ActiveRecord executes a single INSERT statement for every call to 'create'
# and for every call to 'save' on a new model object. When you have only
# a handful of records to create or save this is not a big deal, but when
# you have hundreds, thousands or hundreds of thousands of records
# you need to have better performance.
#
# Below is an example of how to import the least amount of INSERT statements
# using mechanisms provided by your database vendor:
# 
#  class Student < ActiveRecord::Base ; end
#  
#  column_names = Student.columns.map{ |column| column.name }
#  value_sets = some_method_to_load_data_from_csv_file( 'students.csv' )
#  options = { :valudate => true }
#
#  Student.import( column_names, value_sets, options )
#
# The +import+ functionality can be used even if there is not specific
# support for you vendor. This happens when a particular database vendor
# specific enhancement hasn't been added to ActiveRecord::Extensions.
# You can still use +import+ though because the +import+ functionality has
# been created with backwards compatibility. You may still get better
# performance using +import+, but you will definitely get no worse then
# ActiveRecord's create or save methods.
#
# See ActiveRecord::Base.import for more information and other ways to use
# this functionality.
#
# == Developers
# * Zach Dennis 
# * Mark Van Holsytn
#
# == Homepage
# * Project Site: http://www.continuousthinking.com/tags/arext
# * Rubyforge Project: http://rubyforge.org/projects/arext
# * Anonymous SVN: svn checkout svn://rubyforge.org/var/svn/arext
#
module ActiveRecord::Extensions 
  
  Result = Struct.new( :sql, :value )

  # ActiveRecored::Extensions::Registry is used to register finder extensions.
  # Extensions are processed in last in first out order, like a stack.
  class Registry # :nodoc:

    def options( extension )
      extension_arr = @registry.detect{ |arr| arr.first == extension }
      return unless extension_arr
      extension_arr.last
    end

    def registers?( extension ) # :nodoc:
      @registry.detect{ |arr| arr.first == extension }
    end
    
    def register( extension, options ) # :nodoc:
      @registry << [ extension, options ]
    end
      
    def initialize # :nodoc:
      @registry = []
    end

    def process( field, value, caller ) # :nodoc:
      current_adapter = caller.connection.adapter_name.downcase
      @registry.reverse.each do |(extension,options)|
        adapters = options[:adapters]
        adapters.map!{ |e| e.to_s } unless adapters == :all
        next if options[:adapters] != :all and adapters.grep( /#{current_adapter}/ ).empty?
        if result=extension.process( field, value, caller )
          return result
        end
      end
      nil
    end
      
  end
  
  class << self
    extend Forwardable
    
    def register( extension, options ) # :nodoc:
      @registry ||= Registry.new
      @registry.register( extension, options )
    end
     
    def_delegator :@registry, :process, :process
  end
  

  # ActiveRecord::Extension to translate an Array of values
  # into the approriate IN( ... ) or NOT IN( ... ) SQL.
  #
  # == Examples
  #  Model.find :all, :conditions=>{ :id => [ 1,2,3 ] }
  #
  #  # the following three calls are equivalent
  #  Model.find :all, :conditions=>{ :id_ne => [ 4,5,6 ] }
  #  Model.find :all, :conditions=>{ :id_not => [ 4,5,6 ] }
  #  Model.find :all, :conditions=>{ :id_not_in => [ 4,5,6 ] }
  class ArrayExt 
    
    NOT_EQUAL_RGX = /(.+)_(ne|not|not_in)/
    
    def self.process( key, val, caller )
      if val.is_a?( Array )
        match_data = key.to_s.match( NOT_EQUAL_RGX )
        key = match_data.captures[0] if match_data
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )} " +
          (match_data ? 'NOT ' : '') + "IN( ? )"
        return Result.new( str, val )
      end
      nil
    end
    
  end

  
  # ActiveRecord::Extension to translate Hash keys which end in
  # +_lt+, +_lte+, +_gt+, or +_gte+ with the approriate <, <=, >,
  # or >= symbols.
  # * +_lt+ - denotes less than
  # * +_gt+ - denotes greater than
  # * +_lte+ - denotes less than or equal to
  # * +_gte+ - denotes greater than or equal to
  #
  # == Examples
  #  Model.find :all, :conditions=>{ 'number_gt'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_lt'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_gte'=>100 } 
  #  Model.find :all, :conditions=>{ 'number_lte'=>100 }
  class Comparison

    SUFFIX_MAP = { 'eq'=>'=', 'lt'=>'<', 'lte'=>'<=', 'gt'=>'>', 'gte'=>'>=', 'ne'=>'!=', 'not'=>'!=' }
    ACCEPTABLE_COMPARISONS = [ String, Numeric, Time, DateTime ]
    
    def self.process( key, val, caller )
      process_without_suffix( key, val, caller ) || process_with_suffix( key, val, caller )
    end
    
    def self.process_without_suffix( key, val, caller )
      return nil unless caller.columns_hash.has_key?( key )
      if val.nil?
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )} IS NULL"
      else
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )}=?" 
      end
      Result.new( str, val )
    end

    def self.process_with_suffix( key, val, caller ) 
      return nil unless ACCEPTABLE_COMPARISONS.find{ |klass| val.is_a?(klass) }
      SUFFIX_MAP.each_pair do |k,v|
        match_data = key.to_s.match( /(.+)_#{k}$/ )
        if match_data
          fieldname = match_data.captures[0]
          return nil unless caller.columns_hash.has_key?( fieldname )
          str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} " +
            "#{v} #{caller.connection.quote( val, caller.columns_hash[ fieldname ] )} "
          return Result.new( str, nil )
        end
      end
      nil
    end
    
  end

  
  # ActiveRecord::Extension to translate Hash keys which end in
  # +_like+ or +_contains+ with the approriate LIKE keyword
  # used in SQL. 
  #
  # == Examples
  #  # the below two examples are equivalent
  #  Model.find :all, :conditions=>{ :name_like => 'John' }
  #  Model.find :all, :conditions=>{ :name_contains => 'John' }
  #
  #  Model.find :all, :conditions=>{ :name_starts_with => 'J' }
  #  Model.find :all, :conditions=>{ :name_ends_with => 'n' }
  class Like 
    LIKE_RGX = /(.+)_(like|contains)$/
    STARTS_WITH_RGX = /(.+)_starts_with$/
    ENDS_WITH_RGX =  /(.+)_ends_with$/
    def self.process( key, val, caller )
      values = [*val]
      case key.to_s
      when LIKE_RGX
        str = values.collect do |v|
          "#{caller.table_name}.#{caller.connection.quote_column_name( $1 )} LIKE " +
            "#{caller.connection.quote( '%%' + v + '%%', caller.columns_hash[ $1 ] )} "
        end
      when STARTS_WITH_RGX
        str = values.collect do |v|
           "#{caller.table_name}.#{caller.connection.quote_column_name( $1 )} LIKE " +
            "#{caller.connection.quote( v + '%%', caller.columns_hash[ $1 ] )} "
        end
      when ENDS_WITH_RGX
        str = values.collect do |v|
           "#{caller.table_name}.#{caller.connection.quote_column_name( $1 )} LIKE " +
            "#{caller.connection.quote( '%%' + v, caller.columns_hash[ $1 ] )} "
        end
      else
        return nil
      end

      str = str.join(' OR ')
      result_values = []
      str.gsub!(/'((%%)?([^\?]*\?[^%]*|[^%]*%[^%]*)(%%)?)'/) do |match|
        result_values << $2
        '?'
      end
      return Result.new(str , result_values)
    end
  end


  # ActiveRecord::Extension to translate a ruby Range object into SQL's BETWEEN ... AND ...
  # or NOT BETWEEN ... AND ... . This works on Ranges of Numbers, Dates, Times, etc.
  #
  # == Examples
  #  # the following two statements are identical because of how Ranges treat .. and ...
  #  Model.find :all, :conditions=>{ :id => ( 1 .. 2 ) }
  #  Model.find :all, :conditions=>{ :id => ( 1 ... 2 ) }
  #
  #  # the following four statements are identical, this finds NOT BETWEEN matches
  #  Model.find :all, :conditions=>{ :id_ne => ( 4 .. 6 ) }
  #  Model.find :all, :conditions=>{ :id_not => ( 4 .. 6 ) }
  #  Model.find :all, :conditions=>{ :id_not_in => ( 4 ..6 ) }
  #  Model.find :all, :conditions=>{ :id_not_between => ( 4 .. 6 ) }
  #
  #  # a little more creative, working with date ranges
  #  Model.find :all, :conditions=>{ :created_on => (Date.now-30 .. Date.now) }
  class RangeExt 
    NOT_IN_RGX = /^(.+)_(ne|not|not_in|not_between)$/
    
    def self.process( key, val, caller )
      if val.is_a?( Range )
        match_data = key.to_s.match( NOT_IN_RGX )
        key = match_data.captures[0] if match_data
        fieldname = caller.connection.quote_column_name( key )
        min = caller.connection.quote( val.first, caller.columns_hash[ key ] )
        max = caller.connection.quote( val.last, caller.columns_hash[ key ] )
        str = "#{caller.table_name}.#{fieldname} #{match_data ? 'NOT ' : '' } BETWEEN #{min} AND #{max}"
        return Result.new( str, nil )
      end
      nil      
    end
    
  end
 
  # A base class for database vendor specific Regexp implementations. This is meant to be
  # subclassed only because of the helper method(s) it provides.
  class RegexpBase 

    NOT_EQUAL_RGX = /^(.+)_(ne|not|does_not_match)$/
    
    # A result class which provides an easy interface. 
    class RegexpResult
      attr_reader :fieldname, :negate

      def initialize( fieldname, negate=false )
        @fieldname, @negate = fieldname, negate
      end
      
      def negate?
        negate ? true : false
      end
    end
   
    # Given the passed in +str+ and +caller+ this will return a RegexpResult object
    # which gives the database quoted fieldname/column and can tell you whether or not
    # the original +str+ is indicating a negated regular expression.
    #
    # == Examples
    #  r = RegexpBase.field_result( 'id' )
    #  r.fieldname => # 'id'
    #  r.negate?   => # false
    #
    #  r = RegexpBase.field_result( 'id_ne' )
    #  r.fieldname => # 'id'
    #  r.negate?   => # true
    #
    #  r = RegexpBase.field_result( 'id_not' )
    #  r.fieldname => # 'id'
    #  r.negate?   => # true
    #
    #  r = RegexpBase.field_result( 'id_does_not_match' )
    #  r.fieldname => # 'id'
    #  r.negate?   => # true
    def self.field_result( str, caller )
      negate = false
      if match_data=str.to_s.match( NOT_EQUAL_RGX )
        negate = true
        str = match_data.captures[0]
      end      
      fieldname = caller.connection.quote_column_name( str )
      RegexpResult.new( fieldname, negate )
    end
    
  end

  
  # ActiveRecord::Extension for implementing Regexp implementation for MySQL.
  # See documention for RegexpBase.
  class MySQLRegexp < RegexpBase
    
    def self.process( key, val, caller )
      return nil unless val.is_a?( Regexp )
      r = field_result( key, caller )
      Result.new( "#{caller.table_name}.#{r.fieldname} #{r.negate? ? 'NOT ':''} REGEXP ?", val )
    end
    
  end


  # ActiveRecord::Extension for implementing Regexp implementation for PostgreSQL.
  # See documention for RegexpBase.
  #
  # Note: this doesn't support case insensitive matches. 
  class PostgreSQLRegexp < RegexpBase
   
    def self.process( key, val, caller )
      return nil unless val.is_a?( Regexp )
      r = field_result( key, caller )
      return Result.new( "#{caller.table_name}.#{r.fieldname} #{r.negate? ? '!~ ':'~'} ?", val )
    end

  end

  # ActiveRecord::Extension for implementing Regexp implementation for Oracle.
  # See documention for RegexpBase.
  #
  class OracleRegexp < RegexpBase
   
    def self.process( key, val, caller )
      return nil unless val.is_a?( Regexp )
      r = field_result( key, caller )
      return Result.new( "#{r.negate? ? ' NOT ':''} REGEXP_LIKE(#{caller.table_name}.#{r.fieldname} , ?)", val )
    end

  end
  
  
  # ActiveRecord::Extension for implementing Regexp implementation for MySQL.
  # See documention for RegexpBase.
  class SqliteRegexp < RegexpBase
    class_inheritable_accessor :connections
    self.connections = []
    
    def self.add_rlike_function( connection )
      self.connections << connection 
      unless connection.respond_to?( 'sqlite_regexp_support?' )
        class << connection
          def sqlite_regexp_support? ; true ; end
        end
        connection.instance_eval( '@connection' ).create_function( 'rlike', 3 ) do |func, a, b, negate|
          if negate =~ /true/
            func.set_result 1 if a.to_s !~ /#{b}/
          else
            func.set_result 1 if a.to_s =~ /#{b}/
          end
        end
      end
    end 
    
    def self.process( key, val, caller )
      return nil unless val.is_a?( Regexp )
      r = field_result( key, caller )
      unless self.connections.include?( caller.connection )
        add_rlike_function( caller.connection )
      end
      Result.new( "rlike( #{r.fieldname}, ?, '#{r.negate?}' )", val )
    end
        
  end
  
  class DatetimeSupport
    SUFFIX_MAP = { 'eq'=>'=', 'lt'=>'<', 'lte'=>'<=', 'gt'=>'>', 'gte'=>'>=', 'ne'=>'!=', 'not'=>'!=' }
    
    def self.process( key, val, caller )
      return unless val.is_a?( Time )
      process_without_suffix( key, val, caller ) || process_with_suffix( key, val, caller )
    end
    
    def self.process_without_suffix( key, val, caller )
      return nil unless caller.columns_hash.has_key?( key )
      if val.nil?
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )} IS NULL"
      else
        str = "#{caller.table_name}.#{caller.connection.quote_column_name( key )}=" +
          "#{caller.connection.quote( val.to_s(:db), caller.columns_hash[ key ] )} "
      end
      Result.new( str, nil )
    end

    def self.process_with_suffix( key, val, caller )
      SUFFIX_MAP.each_pair do |k,v|
        match_data = key.to_s.match( /(.+)_#{k}$/ )
        if match_data
          fieldname = match_data.captures[0]
          return nil unless caller.columns_hash.has_key?( fieldname )
          str = "#{caller.table_name}.#{caller.connection.quote_column_name( fieldname )} " +
            "#{v} #{caller.connection.quote( val.to_s(:db), caller.columns_hash[ fieldname ] )} "
          return Result.new( str, nil )
        end
      end
      nil
    end


end
  

  register Comparison, :adapters=>:all
  register ArrayExt, :adapters=>:all  
  register Like, :adapters=>:all 
  register RangeExt, :adapters=>:all  
  register MySQLRegexp, :adapters=>[ :mysql ]
  register PostgreSQLRegexp, :adapters=>[ :postgresql ]
  register SqliteRegexp, :adapters =>[ :sqlite ]
  register OracleRegexp, :adapters =>[ :oracle ]
  register DatetimeSupport, :adapters =>[ :mysql, :sqlite, :oracle ]
end



