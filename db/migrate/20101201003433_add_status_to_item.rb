class AddStatusToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :status, :boolean, :default => 0
  end

  def self.down
    remove_column :users, :status
  end
end
