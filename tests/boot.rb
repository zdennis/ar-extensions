dir = File.dirname( __FILE__ )

require File.join( dir, '..', 'boot' )
require 'test/unit'

# TODO fix this to autoload connection
#require File.join( dir, 'connections', 'native_mysql', 'connection.rb' )
require File.join( dir, 'connections', 'native_postgresql', 'connection.rb' )

# Load Models
models_dir = File.join( dir, 'models' )
Dir[ models_dir + '/*.rb'].each { |m| require m }
