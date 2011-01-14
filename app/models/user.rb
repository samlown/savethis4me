class User < ActiveRecord::Base

  has_many :memberships
  has_many :accounts, :through => :memberships
  
  belongs_to :last_used_account, :class_name => 'Account'

  validates_presence_of :identity_url

  protected

  def validate
    if new_record?
      # Check if the user is allowed or denied by the permissions
      config = YAML.load_file("#{RAILS_ROOT}/config/access.yml")
      allow = config['allow'].nil? ? [ ] : config['allow'].to_a
      deny = config['deny'].nil? ? [ ] : config['deny'].to_a
      if !allow.empty?
        if !allow.include?(self.identity_url)
          self.errors.add(:identity_url, "Identity URL is not in allowed list")
        end
      elsif !deny.empty?
        if deny.include?(self.identity_url)
          self.errors.add(:identity_url, "Identity URL is denied")
        end
      end
    end
  end

end
