require 'forwardable' 

# FullTextSearching provides fulltext searching capabilities
# if the underlying database adapter supports it. Currently
# only MySQL is supported.
module ActiveRecord::Extensions::FullTextSearching 

  module FullTextSupport # :nodoc:
    def supports_full_text_searching? #:nodoc:
      true
    end
  end
  
end

class ActiveRecord::Base
  class FullTextSearchingNotSupported < StandardError ; end

  class << self

    # Adds fulltext searching capabilities to the current model
    # for the given fulltext key and option hash.
    #
    # == Parameters
    # * +fulltext_key+ - the key/attribute to be used to as the fulltext index 
    # * +options+ - the options hash.
    #
    # ==== Options
    # * +fields+ - an array of field names to be used in the fulltext search
    #
    # == Example
    #
    #  class Book < ActiveRecord::Base
    #    fulltext :title, :fields=>%W( title publisher author_name )    
    #  end
    #  
    #  # To use the fulltext index
    #  Book.find :all, :conditions=>{ :match_title => 'Zach' }
    #
    def fulltext( fulltext_key, options )
      connection.register_fulltext_extension( fulltext_key, options )
    rescue NoMethodError
      logger.warn "FullTextSearching is not supported for adapter!"
      raise FullTextSearchingNotSupported.new
    end

    # Returns true if the current connection adapter supports full
    # text searching, otherwise returns false.
    def supports_full_text_searching?
      connection.supports_full_text_searching?
    rescue NoMethodError
      false
    end
  end

end






