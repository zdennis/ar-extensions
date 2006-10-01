module ActsAsKeyword ; end

module ActsAsKeyword::ClassMethods

  def self.extended( clazz )
    @@acts_as_keyword = {}
  end

  def acts_as_keyword( options )
    @@acts_as_keyword[ :fields ] = options[ :fields ]
  end

  def find_by_keyword( keyword, options={} )
    conditions,str = [], nil

    qk = connection.quote( keyword )
    quoted_keyword = qk[0..0] + '%' + qk[1..-2] + '%' + qk[-1..-1]
    @@acts_as_keyword[:fields].each { |field|
      str = "#{field} LIKE #{quoted_keyword}" 
      conditions << str }

    options[:conditions] = conditions.join( ' OR ' )
    self.find( :all, options )
  end

end

ActiveRecord::Base.extend( ActsAsKeyword::ClassMethods )

