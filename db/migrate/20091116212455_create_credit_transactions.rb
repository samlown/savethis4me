class CreateCreditTransactions < ActiveRecord::Migration
  def self.up
    create_table :credit_transactions do |t|
      t.references :account
      t.references :archive # optional
      t.references :user
      t.integer :credits
      t.string :concept, :length => 50 
      t.string :bucket
      t.string :key, :length => 1024
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :credit_transactions
  end
end
