module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class OracleAdapter # :nodoc:
       def supports_import?
         true
       end
    end
  end
end
