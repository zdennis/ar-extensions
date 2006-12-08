print "Using native PostgreSQL\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'aroptests'

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :username => "postgres",
  :password => "password",
  :host => 'localhost',
  :database => db1,
  :min_messages => "warning" 
)


