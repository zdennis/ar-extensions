class CartItem < ActiveRecord::Base
  belongs_to :book
  belongs_to :shopping_cart
end