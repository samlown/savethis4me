class Account < ActiveRecord::Base

  has_many :buckets, :order => :name, :dependent => :destroy
  has_many :memberships, :dependent => :delete_all
  has_many :users, :through => :memberships

  belongs_to :last_used_bucket, :class_name => 'Bucket'

  attr_protected :credits
  
  validates_presence_of :access_key_id
  validates_presence_of :secret_access_key

  validates_uniqueness_of :access_key_id

  # Fetch and create all the buckets for this account, delete any old ones.
  def synchronize_buckets
    old_buckets = self.buckets.map{|b| b.name}
    aws_connection.list_all_my_buckets.each do |b|
      unless old_buckets.delete(b[:name])
        self.buckets.create(:name => b[:name])
      end
    end
    old_buckets.each do |name|
      self.buckets.find_by_name(name).destroy
    end
    self.buckets
  end

  # Provide an AWS::S3 connection for this account 
  def aws_connection
    @aws_connection ||= Aws::S3Interface.new(access_key_id, secret_access_key)
  end

  # Try to make a connection to test the keys
  def validate
    aws_connection.list_all_my_buckets
    true
  rescue => err 
    if err.message.include?('InvalidAccessKeyId')
      self.errors.add(:access_key_id, "Invalid access key")
    elsif err.message.include?('SignatureDoesNotMatch')
      self.errors.add(:secret_access_key, "Secret access key does not match")
    else
      self.errors.add_to_base("An error occurred trying to access the AWS service: #{err.message}")
    end
    false
  end

end
