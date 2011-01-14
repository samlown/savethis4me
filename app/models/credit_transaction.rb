class CreditTransaction < ActiveRecord::Base

  belongs_to :account
  belongs_to :archive
  belongs_to :user

  validates_presence_of :account_id

  after_create :append_to_account

  before_update :deny_update

  protected

  def deny_update
    self.errors.add_to_base("Updating a credit transaction is not permitted!")
  end

  def append_to_account
    self.connection.execute("UPDATE accounts SET credits = credits + (#{credits.to_i}) WHERE id = #{account_id}")
  end

end
