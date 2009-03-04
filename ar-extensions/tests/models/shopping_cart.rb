class ShoppingCart < ActiveRecord::Base
  has_many :cart_items
  has_many :books, :through => :cart_items
end