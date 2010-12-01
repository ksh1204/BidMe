class CreateEbayItems < ActiveRecord::Migration
  def self.up
    create_table :ebay_items do |t|
      t.integer :ebay_id
      t.string :title
      t.string :country
      t.string :view_url
      t.float :price
      t.timestamps
    end
  end

  def self.down
    drop_table :ebay_items
  end
end
