class ArchivesController < ApplicationController

  before_filter :load_bucket, :except => [:upload_success]
  before_filter :load_parent, :except => [:upload_success]

  def index
    base = @bucket.archives
    base = @parent_archive ? base.by_parent(@parent_archive) : base.no_parents 

    # TODO Add rules to determine when sync should take place
    @bucket.synchronize(@parent_archive) if params[:full_refresh] == 'true' || base.count == 0

    respond_to do |format|
      format.js do
        new_options = { :parent_id => @parent_archive ? @parent_archive.id : nil }
        render :json => {
          :parent_id => new_options[:parent_id], 
          :hierarchy => @parent_archive ? archives_to_array([@parent_archive] + @parent_archive.ancestors) : [ ],
          :archives => archives_to_array(base.find(:all, :order => 'name')),
          :new_archive_url => upload_new_bucket_archive_url(@bucket, new_options),
          :new_folder_url => new_bucket_archive_url(@bucket, new_options.update(:type => 'folder'))
        }
      end
    end
  end

  # Return a selection of archives for the specific purpose of checking their status
  def queue
    @artifacts = [ ]
    (params[:artifact_ids] ||= []).each do |id|
      @artifacts << Artifact.find(params[:id])
    end

    respond_to do |format|
      format.js do
        render :json => archives_to_array(@artifacts)
      end
    end
  end

  def show
    @archive = @bucket.archives.find(params[:id])
    respond_to do |format|
      format.js do
        render :json => archive_to_hash(@archive)
      end
    end
  end

  def edit
    @archive = @bucket.archives.find(params[:id]) 
    loading_thumb = false
    if @archive.has_thumbnail? and @archive.thumbnail.url.nil? and @archive.updating_at.nil?
      # Send a request for the thumbnail
      Delayed::Job.enqueue ArchiveThumbnailJob.new(@archive.id)
      loading_thumb = true
    end
    respond_to do |format|
      format.js do
        render :json => {
          :view => render_to_string(:partial => 'edit'),
          :loading_thumbnail => loading_thumb,
          :archive => archive_to_hash(@archive)
        }
      end
    end
  end


  def create
    base = @bucket.archives
    base = @parent_archive ? base.by_parent(@parent_archive) : base.no_parents 
    @archive = @bucket.archives.build()
    @archive.parent = @parent_archive
    @archive.attributes = params[:archive]
    success = false
    if params[:type] == 'folder'
      @archive.is_folder!
      success = @archive.save
    elsif params[:archive_id]
      # Check if exists already
      master_archive = @bucket.archives.find(params[:archive_id])
      copy_data = true
      if master_archive.display_name == @archive.display_name
        @archive = master_archive
        copy_data = false
      elsif current_archive = base.find_by_name(@archive.name)
        @archive = current_archive
      end
      # New file name? Copy the data accross.
      @archive.copy_data_from(master_archive) if copy_data and @archive.valid?

      success = @archive.save

      # check for filters, if there are any, send a request
      if @archive.is_image?
        if !(params[:filters] || []).empty? || master_archive.name_extension != @archive.name_extension
          @archive.update_attribute(:updating_at, Time.now)
          filters = [ ]
          (params[:filters] || []).each do |filt| 
            filters << [filt.to_s, params[filt]]
          end
          # send a request to start the image processing
          Delayed::Job.enqueue ArchiveFilterJob.new(@archive.id, filters)
        end
      end
    end
    respond_to do |format|
      if success
        format.js do
          render :json => { :state => 'win', :archive => archive_to_hash(@archive) }
        end
      else
        format.js do
          render :json => { :state => 'fail', :msg => @archive.errors.on(:name).to_a.join(', ') }
        end
      end
    end
  end


  def upload
    respond_to do |format|
      format.js do
        render :json => {
          :view => render_to_string(:partial => 'upload')
        }
      end
    end
  end

  # Receive notification of a completed file upload
  # TODO confirm source URL to avoid DoS
  def upload_success
    key = params[:key]
    bucket = Bucket.find_by_name(params[:bucket])
    raise "Unable to find bucket" if bucket.nil?

    # extract the folder to find the parent, and ask it to refresh itself
    parent = key.gsub(/\/[^\/]+$/, '')
    parent = parent.empty? ? nil : bucket.archives.find_by_name(parent + Archive.folder_suffix)
    base = parent ? bucket.archives.by_parent(parent) : bucket.archives.no_parents

    bucket.synchronize(parent)
    # Now request the thumbnail
    archive = base.find_by_name(key)
    if archive.has_thumbnail?
      Delayed::Job.enqueue ArchiveThumbnailJob.new(archive.id, nil)
    end

    respond_to do |format|
      format.js do
        render :json => {
          :bucket => params[:bucket],
          :key => params[:key],
          :etag => params[:etag],
          :archives_url => bucket_archives_url(bucket, :parent_id => parent ? parent.id : nil)
        }
      end
    end
  end

  def destroy
    @archive = @bucket.archives.find(params[:id])
    respond_to do |format|
      format.js do
        if @archive.aws_destroy
          render :json => { :state => 'win' }
        else
          render :json => { :state => 'fail', :msg => 'Unable to delete archive!' }
        end
      end
    end
  end


  protected

    def load_bucket
      @bucket = current_account.buckets.find_by_name(params[:bucket_id])
    end

    def load_parent
      @parent_archive = @bucket.archives.find(params[:parent_id]) unless params[:parent_id].blank?
    end

    def archives_to_array(archives)
      archives.map {|a| archive_to_hash(a)}
    end

    def archive_to_hash(a)
      archive = {
        :id => a.id,
        :name => a.name,
        :display_name => a.display_name,
        :size => a.size,
        :date => a.date,
        :is_folder => a.is_folder?,
        :is_image => a.is_image?,
        :has_thumbnail => a.has_thumbnail?,
        :url => bucket_archive_url(@bucket, a),
        :edit_url => a.is_folder? ? bucket_archives_url(@bucket, :parent_id => a.id) : edit_bucket_archive_url(@bucket, a),
        :public_url => a.public_url,
        :metadata => a.metadata,
        :updating => a.updating?,
        :updated => a.updated_at.to_i,
        :thumbnail => {
          :url => a.thumbnail.url,
          :icon_url => a.thumbnail.icon.url
        }
      }
     archive
    end
end
