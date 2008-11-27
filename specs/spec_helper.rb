require 'erb'
require 'rubygems'
require 'spec'
require 'active_record'

dir = File.expand_path(File.dirname(__FILE__))
adapter = "mysql"

# prepare database
require File.expand_path(dir + "/connections/#{adapter}")
require 'db/schema/version'
require File.join(dir, "../db/schema/generic" )
schema = File.join(dir, "../db/schema/#{adapter}.rb" )
require schema if File.exists?(schema)

# Load generic models
$: << File.join(dir, "models", "active_record")
Dir[$:.last + '/*.rb'].each { |m| require m }

$:.unshift File.join(dir, "../lib/")

require 'ar-extensions'