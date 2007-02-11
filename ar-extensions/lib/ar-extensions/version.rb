module ActiveRecord # :nodoc:
  module Extensions # :nodoc: 
    module VERSION  
      MAJOR, MINOR, REVISION = %W( 0 4 0 )
      STRING = [ MAJOR, MINOR, REVISION ].join( '.' )
    end
  end
end
