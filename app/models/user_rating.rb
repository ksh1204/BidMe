class UserRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :ratee, :class_name => "User"
end
