# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :require_login

  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|                                                                                 
    "<span class=\"fieldWithErrors\">#{html_tag}</span>"
  end

  # Scrub sensitive parameters from your log
  filter_parameter_logging :secret_access_key

  #### USER'S ACCOUNT HANDLING

  def current_account
    @current_account || account_from_session || users_first_account unless @current_account == false
  end
  
  def current_account=(account)
    session[:account_id] = account ? account.id : nil
    @current_account = account || false
  end

  def current_membership
    if logged_in? and !!current_account
      @current_membership ||= current_user.memberships.find_by_account_id(current_account.id)
    end
  end

  def require_account
    current_account || redirect_to(new_account_url)
  end

  def require_admin
    (logged_in? and current_membership.is_admin?) || redirect_to(accounts_url)
  end

  #### AUTHENTICATION

  def current_user
    @current_user || login_from_session unless @current_user == false
  end

  def current_user=(new_user)
    session[:user_id] = new_user ? new_user.id : nil
    @current_user = new_user || false
  end

  def logged_in?
    !!current_user
  end

  def require_login
    logged_in? || access_denied
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def access_denied
    store_location
    # flash[:warning] = "You need to be logged in first"
    redirect_to new_session_url
  end

  protected

    def login_from_session
      self.current_user = User.find_by_id(session[:user_id]) unless session[:user_id].blank?
    end

    def account_from_session
      self.current_account = current_user.accounts.find(session[:account_id]) unless session[:account_id].blank?  
    end

    def users_first_account
      self.current_account = current_user.accounts.first
    end

end
