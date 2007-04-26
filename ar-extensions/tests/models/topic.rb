class Topic < ActiveRecord::Base
  validates_presence_of :author_name
  has_many :books
end
