class BucketsController < ApplicationController

  before_filter :require_account
  before_filter :require_admin, :only => [:new, :create, :edit, :update, :destroy]

  # Reload all the buckets everytime and show the first of last used
  def index
    if params[:account_id]
      self.current_account = current_user.accounts.find(params[:account_id])
      redirect_to buckets_url
    elsif current_account.synchronize_buckets.length > 0
      # last used
      bucket = current_account.last_used_bucket || current_account.buckets.first
      redirect_to bucket_url(bucket)
    else
      redirect_to account_url(current_account)
    end
  end

  def new
    @bucket = current_account.buckets.build
  end

  def show
    @bucket = current_account.buckets.find_by_name(params[:id])
    current_account.last_used_bucket = @bucket
    current_account.save
    render :action => 'show', :layout => 'bucket'
  end

  def edit
    @bucket = current_account.buckets.find_by_name(params[:id])
    respond_to do |format|
      format.js do
        render :json => {:view => render_to_string(:partial => 'edit')}
      end
    end
  end

  def update
    @bucket = current_account.buckets.find_by_name(params[:id])
    @bucket.attributes = params[:bucket]
    respond_to do |format|
      if @bucket.save
        format.js do
          render :json => {:state => 'win'}
        end
      else
        format.js do
          render :json => {:state => 'fail', :view => render_to_string(:partial => 'edit')}
        end
      end
    end
  end

end
