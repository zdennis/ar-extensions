#!/usr/bin/ruby

ADAPTER = ARGV.shift
ENV["ARE_DB"] = ADAPTER

dir = File.dirname(__FILE__)
require File.expand_path(File.join(dir, "test_helper"))

Dir[File.join(dir, ADAPTER, "test_*.rb") ].each{ |f| require(f) }

Dir[File.join(dir, "test_*.rb")].each do |f|
  require File.expand_path(f) unless f == "test_helper.rb"
end
