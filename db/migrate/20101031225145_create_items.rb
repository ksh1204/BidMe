class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :name
      t.text :description
      t.integer :item_category_id
      t.float :start_price
      t.boolean :bin
      t.float :bin_price
      t.integer :time_limit
      t.string :item_photo_file_name
      t.string :item_photo_content_type
      t.integer :item_photo_file_size
      t.datetime :item_photo_updated_at
      t.boolean :delta, :default => true, :null => false
      t.float :current_price
      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
