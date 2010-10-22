class AddUserFields < ActiveRecord::Migration
  def self.up
     add_column :users, :first_name, :string
     add_column :users, :last_name, :string
     add_column :users, :address, :string
     add_column :users, :phone, :string
     add_column :users, :money, :float, :default => 100.00
     add_column :users, :reset_code, :string
  end

  def self.down
     remove_column :users, :first_name
     remove_column :users, :last_name
     remove_column :users, :address
     remove_column :users, :phone
     remove_column :users, :money
     remove_column :users, :reset_code
  end
end
