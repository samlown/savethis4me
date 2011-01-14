class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string :access_key_id
      t.string :secret_access_key
      t.integer :last_used_bucket_id
      t.timestamps
    end
  end

  def self.down
    drop_table :accounts
  end
end
