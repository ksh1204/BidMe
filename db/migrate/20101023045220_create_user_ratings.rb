class CreateUserRatings < ActiveRecord::Migration
  def self.up
    create_table :user_ratings do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :user_ratings
  end
end
