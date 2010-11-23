class Transaction < ActiveRecord::Base
  belongs_to :buyer, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  belongs_to :item, :class_name => "Item"
end
