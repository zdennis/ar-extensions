#!/usr/bin/ruby

DB_ADAPTER = ARGV.shift

dir = File.dirname( __FILE__ )
require File.join( dir, 'boot' )
Dir[ File.join( dir, 'test_*.rb' ) ].each{ |f| require f }
