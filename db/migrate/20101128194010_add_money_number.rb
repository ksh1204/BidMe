class AddMoneyNumber < ActiveRecord::Migration
  def self.up
    add_column :users, :money_refill, :integer, :default => 5
  end

  def self.down
    remove_column :users, :money_refill
  end
end
