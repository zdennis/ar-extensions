dir = File.dirname( __FILE__ )

require File.join( dir, '..', 'boot' )
require 'test/unit'
require 'active_record/fixtures'

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
end


# TODO fix this to autoload connection
require File.join( dir, 'connections', 'native_mysql', 'connection.rb' )
#require File.join( dir, 'connections', 'native_postgresql', 'connection.rb' )

# Load Models
models_dir = File.join( dir, 'models' )
Dir[ models_dir + '/*.rb'].each { |m| require m }
