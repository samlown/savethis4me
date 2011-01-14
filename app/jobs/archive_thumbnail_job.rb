class ArchiveThumbnailJob < Struct.new(:archive_id)
  
  # Update (or create if none) the archives thumbnail
  # Required :archive_id
  def perform
    archive = Archive.find(archive_id)
    # logger.info("Updating thumbnail for archive")
    archive.update_thumbnail
    archive.save!
  #rescue => e
  #  logger.info "Error updating thumbnail: #{e}"
  end

end
