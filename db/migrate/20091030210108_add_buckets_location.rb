class AddBucketsLocation < ActiveRecord::Migration
  def self.up
    add_column :buckets, :location, :string, :default => 'US', :length => 24
  end

  def self.down
    remove_column :buckets, :location
  end
end
