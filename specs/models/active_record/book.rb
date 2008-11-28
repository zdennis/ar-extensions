class Book < ActiveRecord::Base
end

class BookMyISAM < ActiveRecord::Base
  set_table_name  "book_my_isam"
end