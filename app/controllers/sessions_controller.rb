# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  before_filter :already_logged_in

  # render new.erb.html
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user && !user.is_banned
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      current_ip = request.remote_ip
      last_ip = user.last_ip
      if ((current_ip.eql?(last_ip)) && user.logged_in) || !last_ip || !user.logged_in
        user.update_attributes(:logged_in => true, :last_ip => current_ip)
        update_activity_time
        redirect_back_or_default('/')
        gflash :notice => "Logged in successfully"
      elsif !(current_ip.eql?(last_ip)) && user.logged_in
        gflash :error => "You are already logged in from a different browser/computer"
        render :action => 'new'
      end
    elsif user && user.is_banned
      gflash :error => "You are banned from signing in! Please email BidMe Administrator!"
      render :action => 'new'
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
      #redirect_back_or_default('/')
    end
  end

  def destroy
    current_user.update_attribute(:logged_in, 'false')
    logout_killing_session!
    gflash :notice => "You have been logged out."
    redirect_back_or_default('/')
  end

protected
  # Track failed login attempts
  def note_failed_signin
    if params[:login] == ""
      gflash :error => "You must provide login name"
    else
      gflash :error => "Couldn't log you in as '#{params[:login]}'"
    end
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
  
  def already_logged_in
    if current_user
      gflash :notice => "You are already logged in!"
      redirect_back_or_default('/')
    end
  end
end
