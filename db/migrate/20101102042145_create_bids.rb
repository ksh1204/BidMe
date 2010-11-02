class CreateBids < ActiveRecord::Migration
  def self.up
    create_table :bids do |t|
      t.integer :bidder_id
      t.integer :item_id
      t.float :price

      t.timestamps
    end
  end

  def self.down
    drop_table :bids
  end
end
