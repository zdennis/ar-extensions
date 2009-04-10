require "pathname"

dir = Pathname.new(File.dirname(__FILE__))

require "rubygems"

if version = ENV["AR_VERSION"]
  gem "activerecord", version
else
  gem "activerecord"
end

require "active_record"
require "active_record/version"

require dir.join("connections", "native_#{ENV['ARE_DB']}", "connection.rb")
require dir.join("boot").expand_path
require dir.join("..", "db", "migrate", "version").expand_path

require "mocha"
require "test/unit"
require "fileutils"
require "active_record/fixtures"

## Load Generic Models
models_dir = dir.join("models")
$:.unshift(models_dir)

Dir[models_dir + "/*.rb"].each { |m| require(m) }

## Load Connection Adapter Specific Models
Dir[models_dir.join(ENV["ARE_DB"].downcase) + "/*.rb" ].each { |m| require(m) }

# ActiveRecord 1.14.4 (and earlier supported accessor methods for
# fixture_path as class singleton methods. These tests rely on fixture_path
# being a class instance methods. This is to fix that.
if Test::Unit::TestCase.class_variables.include?("@@fixture_path")
  class Test::Unit::TestCase
    class << self 
      remove_method :fixture_path 
      remove_method :fixture_path=
    end
    class_inheritable_accessor :fixture_path
  end
end

# FIXME: stop using rails fixtures and we won"t have to do things like this
class Fixtures
  def self.cache_for_connection(connection)
    {}
  end

  def self.cached_fixtures(connection, keys_to_fetch = nil)
    []
  end
end

TestCaseSuperClass = if ActiveRecord::VERSION::STRING < "2.3.1"
  Test::Unit::TestCase
else
  ActiveRecord::TestCase
end

class TestCaseSuperClass #:nodoc:
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
end

TestCaseSuperClass.fixture_path = dir.join("fixtures")

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class PostgreSQLAdapter # :nodoc:
      def default_sequence_name(table_name, pk = nil)
        default_pk, default_seq = pk_and_sequence_for(table_name)
        default_seq || "#{table_name}_#{pk || default_pk || "id"}_seq"
      end 
    end
  end
end
