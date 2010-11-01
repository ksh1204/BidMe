class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :buyer_id
      t.integer :seller_id
      t.integer :item_id
      t.float :price
      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end
