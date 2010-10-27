class UserComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :commentee, :class_name => "User"
end
