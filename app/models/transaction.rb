class Transaction < ActiveRecord::Base
  belongs_to :buyer
  belongs_to :seller
  belongs_to :id
end
