adapter = ARGV.shift
ENV['ARE_DB'] = adapter

dir = File.dirname( __FILE__ )
require File.expand_path( File.join( dir, 'boot' ) )

require File.join( dir, '../db/migrate/generic_schema' )
db_schema = File.join( dir, "../db/migrate/#{adapter}_schema.rb" )
require db_schema if File.exists?( db_schema )
