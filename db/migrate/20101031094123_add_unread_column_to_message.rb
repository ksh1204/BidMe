class AddUnreadColumnToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :unread, :boolean, :default => true
  end

  def self.down
    remove_column :messages, :unread
  end
end
