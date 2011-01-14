class ArchiveFilterJob < Struct.new(:archive_id, :filters)
  
  # Perform the selected filters on the archive and upload.
  #
  # Filters are not required, which makes this process useful for changing file formats.
  #
  # Expects a set options as:
  #
  #     :archive_id => Archive ID to update,
  #     :filters => [ [filter, {:option => 'val'}], ... ] # Sent to MagickImageProcessor
  #
  def perform
    archive = Archive.find(archive_id)
    return logger.info("Archive is not an image") unless archive.is_image?

    archive.update_attribute(:updating_at, Time.now) if archive.updating_at.nil?
    image = archive.data_tempfile

    processor = MagickImageProcessor.new(:source_file => image.to_file)
    (filters || []).each do |f|
      f = f.to_a
      processor.add_filter(f[0], f[1])
    end
    tempfile = archive.data_tempfile(true)
    processor.format = archive.extension_to_format
    processor.write(tempfile.to_file)
    archive.upload
    archive.update_from_head
    archive.update_image_metadata
    archive.update_thumbnail
  rescue => e
    puts "Filter Error: #{e}"
    logger.info "Unable to perform filter operations: #{e}"
  ensure
    unless archive.nil?
      archive.updating_at = nil
      archive.save
    end
    image.close unless image.nil?
    tempfile.close unless tempfile.nil?
  end

end
