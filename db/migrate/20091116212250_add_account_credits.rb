class AddAccountCredits < ActiveRecord::Migration
  def self.up
    add_column :accounts, :credits, :integer, :default => 0
  end

  def self.down
    remove_column :accounts, :credits
  end
end
