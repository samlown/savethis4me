class AccountsController < ApplicationController

  def index 
    @accounts = current_user.accounts
  end

  def show
    self.current_account = current_user.accounts.find(params[:id]) if params[:id]
    @buckets = current_membership.buckets
    @memberships = current_account.memberships
  end

  def new
    @account = Account.new
  end

  def create
    Account.transaction do
      @account = Account.new(params[:account])
      if @account.save
        @membership = current_user.memberships.build
        @membership.account = @account
        @membership.save!
        self.current_account = @account
        redirect_to buckets_url
      else
        render :action => 'new'
      end
    end
  end

end
