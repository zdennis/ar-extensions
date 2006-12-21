print "Using native Sqlite\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'aroptests'
dbfile = File.join( File.dirname( __FILE__ ), 'test.db' )

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite",
  :dbfile => dbfile
)

