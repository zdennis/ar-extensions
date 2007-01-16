class Team < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV
  has_many :developers
end
