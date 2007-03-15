#!/usr/bin/ruby

dir = File.dirname( __FILE__ )

ADAPTER = ARGV.shift
ENV['ARE_DB'] = ADAPTER

require 'rubygems'
gem 'ar-extensions'
require 'ar-extensions'

require File.expand_path( File.join( dir, 'test_helper' ) )
Dir[ File.join( dir,  ADAPTER, 'test_*.rb' ) ].each{ |f| require File.expand_path(f) }
Dir[ File.join( dir, 'test_*.rb' ) ].each{ |f| require File.expand_path(f) unless f == 'test_helper.rb' }

