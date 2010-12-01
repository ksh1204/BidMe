class ItemCategory < ActiveRecord::Base
  has_many :items
  attr_accessible :name, :id
end
