module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class AbstractAdapter # :nodoc:
      def self.synchronize(instances, key=ActiveRecord::Base.primary_key)
        return if instances.empty?
        
        keys = instances.map(&"#{key}".to_sym)
        klass = instances.first.class
        fresh_instances = klass.find( :all, :conditions=>{ key=>keys }, :order=>"#{key} ASC" )

        instances.each_with_index do |instance, index|
          instance.clear_aggregation_cache
          instance.clear_association_cache
          instance.instance_variable_set '@attributes', fresh_instances[index].attributes
        end
      end
      
      def synchronize(instances, key=ActiveRecord::Base.primary_key)
        self.class.synchronize(instances, key)
      end
    end
  end
end