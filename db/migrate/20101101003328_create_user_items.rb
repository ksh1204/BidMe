class CreateUserItems < ActiveRecord::Migration
  def self.up
    create_table :user_items do |t|
      t.integer :user_id
      t.integer :item_id
      t.timestamps
    end
  end

  def self.down
    drop_table :user_items
  end
end
