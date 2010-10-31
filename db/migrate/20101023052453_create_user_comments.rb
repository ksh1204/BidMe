class CreateUserComments < ActiveRecord::Migration
  def self.up
    create_table :user_comments do |t|
      t.integer :user_id
      t.integer :commentee_id
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :user_comments
  end
end
