#Extend this module on ActiveRecord to access global functions
class ExtensionNotSupported < Exception; end;

module ActiveRecord
  module Extensions
    module SupportMethods#:nodoc:
      def supports_extension(name)
        class_eval(<<-EOS, __FILE__, __LINE__)
          def self.supports_#{name}?#:nodoc:
            connection.supports_#{name}?
          rescue NoMethodError
           false
          end

          def supports_#{name}?#:nodoc:
            self.class.supports_#{name}?
          end

          def self.supports_#{name}!#:nodoc:
            supports_#{name}? or raise ExtensionNotSupported.new("#{name} extension is not supported. Please require the adapter file.")
          end

          def supports_#{name}!#:nodoc:
            self.class.supports_#{name}!
          end
        EOS
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Extensions::SupportMethods
