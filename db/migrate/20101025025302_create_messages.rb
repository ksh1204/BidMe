class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
