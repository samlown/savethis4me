class SessionsController < ApplicationController

  skip_before_filter :require_login

  def new
    if logged_in?
      redirect_to buckets_url
    end
  end

  def create
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        if self.current_user = User.find_by_identity_url(identity_url)
          redirect_back_or_default(root_url)
        else
          # Create the new user
          @user = User.create(:identity_url => identity_url)
          if @user.valid?
            self.current_user = @user
            redirect_to new_account_url
          else
            failed_login "Unable to create new user"
          end
        end
      else
        failed_login result.message
      end
    end
  end

  def destroy
    self.current_user = nil
    self.current_account = nil
    redirect_to new_session_url
  end

  protected

    def failed_login(message)
      flash[:error] = message
      redirect_to(new_session_url)                                                                                                                   
    end  

end
