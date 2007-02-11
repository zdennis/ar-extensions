# Enables support for enabling and disabling foreign keys
# for the underlyig database connection for ActiveRecord.
#
# This can be used with or without block form. This also
# uses the connection attached to the model.
#
# ==== Example 1, without block form
#   Project.foreign_keys.disable
#   Project.foreign_keys.enable  
#  
# If you use this form you have to manually re-enable the foreign
# keys.
#
# ==== Example 2, with block form
#   Project.foreign_keys.disable do 
#     # ...
#   end
#
#  Project.foreign_keys.enable do
#    # ...
#  end
#
# If you use the block form the foreign keys are automatically
# enabled or disabled when the block exits. This currently
# does not restore the state of foreign keys to the state before
# the block was entered. 
#
# Note: If you use the disable block foreign keys
# will be enabled after the block exits. If you use the enable block foreign keys
# will be disabled after the block exits.
#
# TODO: check the external state and restore that state when using block form.
module ActiveRecord::Extensions::ForeignKeys

  class ForeignKeyController # :nodoc:
    attr_reader :clazz

    def initialize( clazz )
      @clazz = clazz
    end

    def disable # :nodoc:
      if block_given?
        disable
        yield
        enable
      else
        clazz.connection.execute "set foreign_key_checks = 0"
      end
    end
    
    def enable #:nodoc:
      if block_given?
        enable
        yield
        disable
      else
        clazz.connection.execute "set foreign_key_checks = 1"
      end
    end
   
  end #end ForeignKeyController
  
  def foreign_keys # :nodoc:
    ForeignKeyController.new( self )
  end

end

ActiveRecord::Base.extend( ActiveRecord::Extensions::ForeignKeys )
