require 'forwardable' 

module ActiveRecord::Extensions::FullTextSearching
  class FullTextSearchingNotSupported < StandardError ; end
  
  module FullTextSupport
    def supports_full_text_searching?
      true
    end
  end
  
  module ClassMethods    
    def fulltext( fulltext_key, options )
      connection.register_fulltext_extension( fulltext_key, options )
    rescue NoMethodError
      # raise FullTextSearchingNotSupported.new
      # DO NOT RAISE EXCEPTION, PRINT A WARNING AND DO NOTHING
      ActiveRecord::Base.logger.warn "FullTextSearching is not supported for adapter!"
    end
  end
end

class ActiveRecord::Base
  def self.supports_full_text_searching?
    connection.supports_full_text_searching?
  rescue NoMethodError
    false
  end
end

ActiveRecord::Base.extend( ActiveRecord::Extensions::FullTextSearching::ClassMethods )




