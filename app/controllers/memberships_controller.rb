class MembershipsController < ApplicationController

  before_filter :require_account
  before_filter :require_admin

  def new
    @membership = current_account.memberships.build
    @membership.role = 'admin' # default role
    edit
  end

  def create
    @membership = current_account.memberships.build()
    update
  end

  def edit
    @membership ||= current_account.memberships.find(params[:id])
    respond_to do |format|
      format.js do
        render :json => {:view => render_to_string(:partial => 'edit')}
      end
    end
  end

  def update
    @membership ||= current_account.memberships.find(params[:id])
    @membership.attributes = params[:membership]
    @membership.user = User.find_or_create_by_identity_url(OpenIdAuthentication.normalize_url(params[:user][:identity_url])) if @membership.new_record?
    @membership.role = params[:membership][:role]
    @membership.role = 'user' unless ['admin', 'user'].include?(@membership.role)
    respond_to do |format|
      if @membership.user.valid? && @membership.save
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

  def destroy
    @membership = current_account.memberships.find(params[:id])
    respond_to do |format|
      format.js do
        if (@membership.destroy)
          render :json => {:state => 'win'}
        else
          render :json => {:state => 'fail', :msg => "Unable to destroy membership!"}
        end
      end
    end
  end


end
