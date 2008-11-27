require 'singleton'

module ContinuousThinking::SQL
  class Templates < Array
    include Singleton
  end
  
  def self.templates
    Templates.instance
  end
  
  def self.define_template(identifier, &blk)
    templates << Template.new(identifier, &blk)
  end
  private_class_method :define_template
  
  define_template :insert_into do
    body "INSERT INTO :table :columns VALUES :values"
    mapping :table => lambda { |table| table }
    mapping :columns => lambda { |columns| "(#{columns.join(',')})" }
    mapping :values => lambda { |values| values.map{ |row| "(#{row.join(',')})" }.join(',') }
  end
end