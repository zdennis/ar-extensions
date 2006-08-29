print "Using native MySQL\n"
#require_dependency 'fixtures/course'
#require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'ar_benchmarks'

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :username => "rails",
  :encoding => "utf8",
  :database => db1
)

