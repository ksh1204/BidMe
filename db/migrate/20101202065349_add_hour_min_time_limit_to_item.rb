class AddHourMinTimeLimitToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :time_limit_hours, :integer, :default => 0
    add_column :items, :time_limit_minutes, :integer, :default => 0
  end

  def self.down
    remove_column :items, :time_limit_hours
    remove_column :items, :time_limit_hours
  end
end
