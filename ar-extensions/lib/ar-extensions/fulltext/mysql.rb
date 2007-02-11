# This adds FullText searching functionality for the MySQLAdapter.
class ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension
  extend Forwardable
  
  class << self
    extend Forwardable
    
    def register( fulltext_key, options ) # :nodoc:
      @fulltext_registry ||= ActiveRecord::Extensions::Registry.new
      @fulltext_registry.register( fulltext_key, options )
    end
    
    def registry # :nodoc:
      @fulltext_registry
    end
    
    def_delegator :@fulltext_registry, :registers?, :registers?
  end
  
  RGX = /^match_(.+)/
  
  def process( key, val, caller ) # :nodoc:
    match_data = key.to_s.match( RGX )
    return nil unless match_data
    fulltext_identifier = match_data.captures[0].to_sym
    if self.class.registers?( fulltext_identifier )
      fields = self.class.registry.options( fulltext_identifier )[:fields]
      str = "MATCH ( #{fields.join( ',' )} ) AGAINST (#{caller.connection.quote(val)})"
      return ActiveRecord::Extensions::Result.new( str, nil )
    end
    nil
  end
  
  def_delegator 'ActiveRecord::Extensions::FullTextSupport::MySQLFullTextExtension', :register    
end
ActiveRecord::Extensions.register ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension.new, :adapters=>[:mysql]

class ActiveRecord::ConnectionAdapters::MysqlAdapter # :nodoc:
  include ActiveRecord::Extensions::FullTextSearching::FullTextSupport

  def register_fulltext_extension( fulltext_key, options ) # :nodoc:
    ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension.register( fulltext_key, options )
  end
end
