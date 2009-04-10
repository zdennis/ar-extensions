puts "Using native MySQL"

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations["test"] = {
  :adapter  => "mysql",
  :username => "zdennis",
  :encoding => "utf8",
  :host     => "localhost",
  :database => "aroptests"
}

ActiveRecord::Base.establish_connection("test")
