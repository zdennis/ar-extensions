module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class OracleAdapter # :nodoc:
      
      def next_value_for_sequence(sequence_name)
        %{#{sequence_name}.nextval}
      end
      
      def supports_import?
        true
      end
    end
  end
end
