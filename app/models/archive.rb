class Archive < ActiveRecord::Base

  acts_as_tree

  belongs_to :bucket

  mount_uploader :thumbnail, ArchiveThumbnailUploader

  validates_uniqueness_of :name, :scope => :bucket_id

  named_scope :no_parents, :conditions => ['archives.parent_id IS NULL']
  named_scope :by_parent, lambda {|parent| {:conditions => ['archives.parent_id = ?', parent.id]}}
  named_scope :name_order, :order => ['archives.name']

  serialize :metadata, Hash

  def display_name
    @display_name ||= name.to_s.gsub(/^.*\//, '').gsub(/_\$folder\$$/, '')
  end

  # Set the display name and update the stored name
  def display_name=(name)
    @display_name = name
    new_name = generate_prefix_path + name 
    new_name += self.class.folder_suffix if is_folder?
    self.name = new_name
  end

  def name_extension
    name[/\.([\w\d]{2,})$/i, 1].to_s.downcase
  end

  def is_image?
    %w(jpg jpeg png gif).include? name_extension
  end

  def extension_to_format
    case name_extension
    when 'jpg', 'jpeg'
      'JPEG'
    when 'png'
      'PNG'
    when 'gif'
      'GIF'
    else
      ''
    end
  end

  def is_folder?
    name.to_s =~ /#{Regexp.escape(self.class.folder_suffix)}$/ ? true : false
  end
  def is_folder!
    self.name += self.class.folder_suffix unless is_folder?
  end

  def has_thumbnail?
    is_image? && size < 5.megabytes
  end

  def updating?
    !self.updating_at.nil? and self.updating_at > 20.minutes.ago
  end

  # Provide a url for the archives icon, either using a preview
  # or using the default icon.
  # TODO Generate the URLs in a better place, and make paths!
  def icon_url
    if is_folder?
      '/images/icons/folder-48x48.png'
    elsif is_image?
      # Is there a real thumb available?
      self.thumbnail.url ? self.thumbnail.icon.url : '/images/icons/image-48x48.png'
    else
      '/images/icons/document-48x48.png'
    end
  end

  def thumb_url
    if is_folder?
      '/images/icons/folder-48x48.png'
    elsif is_image?
      # Is there a real thumb available?
      self.thumbnail.url ? self.thumbnail.url : '/images/icons/image-48x48.png'
    else
      '/images/icons/document-48x48.png'
    end
  end

  def public_uri
    URI::Generic.build(:scheme => 'http', :host => self.bucket.cname, :path => '/').merge(URI.escape(URI.escape(self.name), /[\[\]]/).gsub(/%20/, '+'))
  end

  def public_url
    public_uri.to_s
  end

  def update_thumbnail
    if has_thumbnail?
      update_image_metadata
      self.thumbnail = data_tempfile
    end
  end
 
  def update_image_metadata
    image = Magick::Image.ping(data_tempfile.to_file).first
    return if image.nil?
    self.metadata ||= { }
    metadata['width'] = image.columns
    metadata['height'] = image.rows
    metadata['format'] = image.format
    # metadata['image_type'] = image.image_type
    logger.info("Image size found as: #{image.columns}x#{image.rows}")
    image.destroy!
  rescue ::Magick::ImageMagickError => e
    logger.info "Failed to update image meta data: #{e}"
  end


  def data_tempfile(no_data = false)
    if no_data or @data_tempfile.nil?
      @data_tempfile = Tempfile.new("data.#{name_extension}")
      unless no_data
        @data_tempfile.write(data)
        @data_tempfile.rewind
        # @data_tempfile.pos = 0
      end
    end
    @data_tempfile.rewind
    @data_tempfile
  end

  # Wrapper to fetch the real data of the archive from the source.
  def data
    aws_data
  end

  # Read the data tempfile and upload its contents to S3.
  def upload
    aws_upload(data_tempfile.read)
  end

  # Copy the data from the old archive to this one. This operation is performed
  # directly on S3.
  def copy_data_from(archive)
    archive.aws_copy(self.name)
    head = self.aws_head
    if !head[:last_modified].blank?
      update_from_head(head)
      true
    else
      false
    end
  end

  ###### AWS Access methods

  def aws_head
    bucket.account.aws_connection.head(bucket.name, name)
  end

  def aws_data
    bucket.account.aws_connection.get_object(bucket.name, name)
  end

  # Delete from AWS, then destroy the local copy
  def aws_destroy
    bucket.account.aws_connection.delete(bucket.name, name)
    self.destroy
  rescue
    false
  end

  # With the file prepared locally, upload it to aws
  def aws_upload(file)
    logger.info "Uploading file: #{name}"
    bucket.account.aws_connection.put(bucket.name, name, file, 'x-amz-acl' => 'public-read')
  end

  # Copy the current archive to the specified file leaving the 
  # original as it was.
  # Provides the new AWS key
  def aws_copy(new_name)
    # Set the permissions on the new key
    bucket.account.aws_connection.copy(bucket.name, name, bucket.name, new_name, :copy, 'x-amz-acl' => 'public-read')
  end

  def update_from_head(head = aws_head)
    self.etag = head['etag']
    self.date = head['last-modified']
    self.size = head['content-length']
  end

  ######

  def synchronize_children
    return unless is_folder?
    bucket.synchronize(self)
  end

  # Calculate the path, if folder, includes self 
  def prefix_path
    if is_folder?
      name.gsub(/#{Regexp.escape(self.class.folder_suffix)}$/, '') + '/'
    else
      name.gsub(/[^\/]+$/, '')
    end
  end

  # Rather than using the name, recursively use the archives hierarchy to create path
  def generate_prefix_path
    if self.parent
      self.parent.generate_prefix_path + self.parent.display_name + '/'
    else
      ''
    end
  end

  def self.folder_suffix
    '_$folder$'
  end

  # Find or create a new folder with the provided name.
  # Name is filtered before use to remove and end slashes and add
  # the necessary folder suffix.
  def self.find_or_create_folder(basket, parent, name, attribs = {})
    name = name.gsub(/\/$/, '') + folder_suffix
    basket.archives.find_by_name(name) || basket.archives.create(attribs.update(:parent_id => (parent ? parent.id : nil), :name => name))
  end

  protected
    
    def after_initialize
      self.metadata ||= { }
      self.size = 0 unless self.attributes['size'] 
    end


end
