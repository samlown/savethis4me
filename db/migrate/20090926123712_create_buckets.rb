class CreateBuckets < ActiveRecord::Migration
  def self.up
    create_table :buckets do |t|
      t.references :account
      t.string :name
      t.string :cname # used for URLs
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :buckets
  end
end
