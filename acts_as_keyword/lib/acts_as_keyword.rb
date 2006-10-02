module ActsAsKeyword ; end

module ActsAsKeyword::ClassMethods

  def self.extended( clazz )
    @@acts_as_keyword = {}
  end

  def acts_as_keyword( options )
    @@acts_as_keyword[ :fields ] = options[ :fields ]
  end

  def build_keyword_conditions( keyword )
    conditions, str = [], nil
    qk = connection.quote( keyword )
    quoted_keyword = qk[0..0] + '%' + qk[1..-2] + '%' + qk[-1..-1]
    @@acts_as_keyword[:fields].each { |field|
      str = "#{self.table_name}.#{field} LIKE #{quoted_keyword}" 
      conditions << str }
    conditions.join( ' OR ' )
  end

  def count_by_keyword( keyword, options={} )
    conditions = build_keyword_conditions( keyword )
STDERR.puts __LINE__,options.inspect
    merge_finder_conditions_with_keyword_conditions( conditions, options )   
STDERR.puts __LINE__,options.inspect
    self.count( options )
  end

  def find_by_keyword( keyword, options={} )
    conditions = build_keyword_conditions( keyword )
    merge_finder_conditions_with_keyword_conditions( conditions, options )
    self.find( :all, options )
  end

  def merge_finder_conditions_with_keyword_conditions( conditions, options )
    options[:conditions] = nil unless options.has_key?( :conditions )
    case options[:conditions].class
      when String
        options[:conditions] << " #{conditions}"
      when Array
        options[:conditions][0] << " #{conditions}"
      when Hash
        options[:conditions] = [ conditions, options[:conditions] ]
      else
        options[:conditions] = conditions
    end
  end

end

ActiveRecord::Base.extend( ActsAsKeyword::ClassMethods )

