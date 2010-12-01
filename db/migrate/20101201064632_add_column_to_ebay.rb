class AddColumnToEbay < ActiveRecord::Migration
  def self.up
    add_column :ebay_items, :keyword, :string
  end

  def self.down
    remove_column :ebay_items, :keyword
  end
end
