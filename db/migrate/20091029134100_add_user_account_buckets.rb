class AddUserAccountBuckets < ActiveRecord::Migration
  def self.up
    rename_table :user_accounts, :memberships
    add_column :users, :last_used_account, :integer
    add_column :memberships, :bucket_ids, :text
    add_column :memberships, :role, :string, :default => 'owner', :limit => 16
  end

  def self.down
    rename_table :memberships, :user_accounts
    remove_column :users, :last_used_account
    remove_column :user_accounts, :bucket_ids
    remove_column :user_accounts, :role
  end
end
