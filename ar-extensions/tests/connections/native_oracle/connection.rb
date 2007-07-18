print "Using native Oracle\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

config = ActiveRecord::Base.configurations['test'] = {   :adapter  => "oracle",
  :username => "arext_development",
  :password => "arext",
  :database => "activerecord_unittest",
  :min_messages => "debug" }

ActiveRecord::Base.establish_connection( config )



