class Developer < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV

  has_many :addresses
  belongs_to :team
end

