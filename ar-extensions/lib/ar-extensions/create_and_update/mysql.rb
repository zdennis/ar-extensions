# Although the finder options actually override ActiveRecord::Base functionality instead of
# connector functionality, the methods are included here to keep the syntax of 0.8.0 intact
#
# To include finder options, use:
# require 'ar-extensions/create_and_update/mysql.rb'

ActiveRecord::Base.send :include, ActiveRecord::Extensions::CreateAndUpdate
