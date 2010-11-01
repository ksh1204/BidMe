class CreateWatches < ActiveRecord::Migration
  def self.up
    create_table :watches do |t|
      t.integer :watcher_id
      t.integer :item_id
      t.timestamps
    end
  end

  def self.down
    drop_table :watches
  end
end
