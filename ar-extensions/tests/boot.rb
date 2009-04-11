require "yaml"
require "pathname"

dir = Pathname.new(File.dirname(__FILE__))

libdir = dir.join("..", "lib", "ar-extensions").expand_path
require libdir
require "ar-extensions/csv"

## Connection

puts "Using native #{ENV['ARE_DB']}"

ActiveRecord::Base.logger = Logger.new("debug.log")
ActiveRecord::Base.configurations["test"] = YAML.load(dir.join("database.yml").open)[ENV["ARE_DB"]]
ActiveRecord::Base.establish_connection("test")

## Load all database adapter specific stuff. This has to happen after the 
## connection has been established.

Dir[libdir.join("**", "#{ENV['ARE_DB']}.rb")].each do |f|
  require(f)
end
