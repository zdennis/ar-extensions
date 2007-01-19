module ActiveRecord::Extensions::ForeignKeys

  class ForeignKeyController
    attr_reader :clazz

    def initialize( clazz )
      @clazz = clazz
    end


    #TODO: Dont modify external state
    def disable
      if block_given?
        disable
        yield
        enable
      else
        clazz.connection.execute "set foreign_key_checks = 0"
      end
    end
    
    def enable
      if block_given?
        enable
        yield
        disable
      else
        clazz.connection.execute "set foreign_key_checks = 1"
      end
    end
   
  end #end ForeignKeyController
  
  def foreign_keys
    ForeignKeyController.new( self )
  end

end

ActiveRecord::Base.extend( ActiveRecord::Extensions::ForeignKeys )
