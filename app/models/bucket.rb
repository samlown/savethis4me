class Bucket < ActiveRecord::Base

  belongs_to :account

  has_many :archives, :dependent => :destroy, :order => 'archives.name'

  validates_uniqueness_of :name, :scope => :account_id

  MAX_KEYS = 200

  def self.locations
    [
      ['US', "U.S."],
      ['EU', "Europe"]
    ]
  end

  def to_param
    name
  end

  # Provide the default cname if none already set
  def cname
    value = read_attribute(:cname)
    @cname ||= value.blank? ? (new_record? ? "" : "#{name.gsub(/\_/, '-')}.s3.amazonaws.com") : value
  end

  # Wrapper for accessing AWS Bucket object
  def aws_bucket
    account.aws_connection.bucket(name)
  end

  def synchronize(parent = nil)
    base = parent.nil? ? archives.no_parents : archives.by_parent(parent)
    prefix = parent.nil? ? '' : parent.prefix_path

    original_archives = base.find(:all, :limit => MAX_KEYS).map{|a| a.name}

    # Send request to server for items
    account.aws_connection.incrementally_list_bucket(self.name, 'prefix' => prefix, 'max-keys' => MAX_KEYS, 'delimiter' => '/') do |response|
      # Create common_prefixes directories first
      (response[:common_prefixes] || []).each do |name|
        archive = Archive.find_or_create_folder(self, parent, name)
        original_archives.delete(archive.name)
      end
      response[:contents].each do |obj|
        next if obj[:key] =~ /\/$/
        archive = base.find_by_name(obj[:key])
        archive ||= self.archives.build(:parent_id => (parent ? parent.id : nil))
        archive.attributes = {
          :name => obj[:key],
          :etag => obj[:e_tag],
          :date => obj[:last_modified],
          :size => obj[:size]
        }
        archive.updating_at = nil unless archive.updating?
        if archive.changed? or archive.new_record?
          archive.thumbnail = nil # Remove the current thumbnail
          archive.save
        end
        original_archives.delete(obj[:key])
      end
    end

    # remove any old archives
    original_archives.each {|a| base.find_by_name(a).destroy}
    true
  end


end
