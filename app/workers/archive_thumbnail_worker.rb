class ArchiveThumbnailWorker < Workling::Base
  
  # Update (or create if none) the archives thumbnail
  # Required :archive_id
  def update_thumbnail(options)
    archive = Archive.find(options[:archive_id])
    logger.info("Updating thumbnail for archive")
    archive.update_thumbnail
    archive.save!
  #rescue => e
  #  logger.info "Error updating thumbnail: #{e}"
  end

end
