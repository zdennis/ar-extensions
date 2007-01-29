print "Using native PostgreSQL\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'aroptests'

config = ActiveRecord::Base.configurations['test'] = {   :adapter  => "postgresql",
  :username => "postgres",
  :password => "password",
  :host => 'localhost',
  :database => db1,
  :min_messages => "warning" }

ActiveRecord::Base.establish_connection( config )



