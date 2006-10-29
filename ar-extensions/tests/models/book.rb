class Book < ActiveRecord::Base
  fulltext :title, :fields=>%W( title publisher author_name )
end
