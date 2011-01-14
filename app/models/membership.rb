class Membership < ActiveRecord::Base

  belongs_to :user
  belongs_to :account

  serialize :bucket_ids, Array

  attr_protected :role, :user, :user_id, :account, :account_id

  def self.roles
    [
      ['owner', 'Owner'],
      ['admin', 'Administrator'],
      ['user', 'User']
    ]
  end

  def role_name
    self.class.roles.assoc(self.role).last
  end

  def buckets
    bucket_ids.empty? ? account.buckets : account.buckets.find(:all, :conditions => ['buckets.id IN (?)', self.bucket_ids])
  end

  def is_owner?
    role == 'owner'
  end
  def is_admin?
    ['owner', 'admin'].include? role
  end

  protected

  def after_initialize
    self.bucket_ids ||= [ ]
  end

end
