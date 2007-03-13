print "Using native MySQL\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'aroptests'

config = ActiveRecord::Base.configurations['test'] = { :adapter  => "mysql",
  :username => "zdennis",
  :encoding => "utf8",
  :host => '127.0.0.1',
  :database => db1 }

ActiveRecord::Base.establish_connection( config )

