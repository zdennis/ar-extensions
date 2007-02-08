class Developer < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV

  has_many :addresses
  has_many :languages
  belongs_to :team
end

