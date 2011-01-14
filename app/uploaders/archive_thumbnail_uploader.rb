# encoding: utf-8

class ArchiveThumbnailUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support
  # include CarrierWave::RMagick
  # include CarrierWave::ImageScience
  include CarrierWave::MiniMagick

  # Automatically load the configuration for this environment
  YAML::load(File.open(Rails.root.join("config/carrierwave.yml")))[Rails.env].each {|k, v| send(k, v)}

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.bucket.name}/#{mounted_as}/#{model.id}"
  end

  # Provide a default path as a default if there hasn't been a file uploaded
  #     def default_path
  #       "images/fallback/" + [version_name, "default.png"].compact.join('_')
  #     end

  process :resize_to_limit => [150, 150]
  

  version :icon do
    #process :crop_resized => [48, 48]
    process :resize_to_limit => [48, 48]
  end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #def extension_white_list
  #  %w(jpg jpeg gif png)
  #end

  # Override the filename of the uploaded files
  def filename
    "image.#{model.name_extension}" if original_filename
  end

  def self.load_configuration
  end
end
