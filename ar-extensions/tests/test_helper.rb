dir = File.dirname( __FILE__ )

require File.expand_path( File.join( dir, '..', 'db', 'migrate', 'version' ) )
require 'mocha'
require 'test/unit'
require 'fileutils'
require 'active_record/fixtures'

# ActiveRecord 1.14.4 (and earlier supported accessor methods for
# fixture_path as class singleton methods. These tests rely on fixture_path
# being a class instance methods. This is to fix that.
if Test::Unit::TestCase.class_variables.include?( '@@fixture_path' )
  class Test::Unit::TestCase
    class << self 
      remove_method :fixture_path 
      remove_method :fixture_path=
    end
    class_inheritable_accessor :fixture_path
  end
end

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
#$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
class Test::Unit::TestCase #:nodoc:

#  def self.fixtures(*table_names)
#    if block_given?
#      Fixtures.create_fixtures(self.fixture_path, table_names) { yield }
#    else
#      Fixtures.create_fixtures(self.fixture_path, table_names)
#    end
#  end
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
end

require File.join( dir, 'connections', "native_#{ENV["ARE_DB"]}", 'connection.rb' )

# Load Generic Models
models_dir = File.join( dir, 'models' )
Dir[ models_dir + '/*.rb'].each { |m| require m }

# Load Connection Adapter Specific Models
models_dir = File.join( dir, 'models', ENV['ARE_DB'].downcase )
Dir[ models_dir + '/*.rb' ].each{ |m| require m }



module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class PostgreSQLAdapter # :nodoc:
      def default_sequence_name(table_name, pk = nil)
        default_pk, default_seq = pk_and_sequence_for(table_name)
        default_seq || "#{table_name}_#{pk || default_pk || 'id'}_seq"
      end 
    end
  end
end
