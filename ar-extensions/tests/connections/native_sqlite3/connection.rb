puts "Using native Sqlite3"

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations["test"] = {
  :adapter => "sqlite3",
  :dbfile  => File.join(File.dirname(__FILE__), "test.db")
}

ActiveRecord::Base.establish_connection("test")

