puts "Using native Oracle"

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations["test"] = {
  :adapter  => "oracle",
  :username => "arext_development",
  :password => "arext",
  :database => "activerecord_unittest",
  :min_messages => "debug"
}

ActiveRecord::Base.establish_connection("test")
