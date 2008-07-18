class Topic < ActiveRecord::Base
  validates_presence_of :author_name
  has_many :books
  
  composed_of :description, :mapping => [ %w(title title), %w(author_name author_name)], :allow_nil => true, :class_name => "TopicDescription"
end

class TopicDescription
  attr_reader :title, :author_name
  def initialize(title, author_name)
    @title, @author_name = title, author_name
  end
end