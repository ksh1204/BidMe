class CreateFollows < ActiveRecord::Migration
  def self.up
    create_table :follows do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :follows
  end
end