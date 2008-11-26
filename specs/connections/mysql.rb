ActiveRecord::Base.logger = Logger.new("debug.log")

config = { 
  :adapter  => "mysql",
  :username => "zdennis",
  :encoding => "utf8",
  :host => '127.0.0.1',
  :database => "arext_test" }
ActiveRecord::Base.configurations['test'] = config
ActiveRecord::Base.establish_connection( config )

