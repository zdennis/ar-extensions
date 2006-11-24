dir = File.dirname( __FILE__ )

require File.join( dir, '..', 'boot' )
require 'test/unit'
require 'active_record/fixtures'
require 'breakpoint'

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
class Test::Unit::TestCase #:nodoc:
  def self.fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
end

require File.join( dir, 'connections', "native_#{ENV["ARE_DB"]}", 'connection.rb' )

# Load Models
models_dir = File.join( dir, 'models' )
Dir[ models_dir + '/*.rb'].each { |m| require m }
