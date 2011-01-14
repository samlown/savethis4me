class CreateArchives < ActiveRecord::Migration
  def self.up
    create_table :archives do |t|
      t.references :bucket
      t.integer :parent_id
      t.string :name
      t.string :access
      t.integer :size
      t.string :content_type
      t.string :etag
      t.datetime :date
      t.string :public_url
      t.string :thumbnail
      t.text :metadata
      t.text :notes
      t.datetime :updating_at
      t.timestamps
    end
  end

  def self.down
    drop_table :archives
  end
end
