class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  before_filter :login_required, :except => [:new, :create, :activate, :forgot, :reset]

  # render new.rhtml
  def new
    @user = User.new
  end
  
  def home
    @user = current_user
  end
  
  def edit
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
  
  def update
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    if @user.update_attributes(params[:user])
      flash[:notice] = "Profile Successfully Updated"
      if current_user.is_admin?
        redirect_to :action => 'list'
      else
        redirect_to :action => 'home'
      end
    else
      render :action => 'edit', :id => params[:id]
    end
  end
  
  def update_password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    if @user.update_attributes(params[:user])
      flash[:notice] = "Password Successfully Updated"
      redirect_to :action => 'edit', :id => @user.id
    else
      render :action => 'change_password', :id => params[:id]
    end
  end
  
  def change_password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
  
  def forgot
      if request.post?
        user = User.find_by_email(params[:user][:email])
        if user
          user.create_reset_code
          flash[:notice] = "Reset code sent to #{user.email}"
        else
          flash[:notice] = "#{params[:user][:email]} does not exist in system"
        end
        redirect_back_or_default('/')
      end
    end

    def reset
      @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
      if request.post?
        if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
          self.current_user = @user
          @user.delete_reset_code
          flash[:notice] = "Password reset successfully for #{@user.email}"
          redirect_back_or_default('/')
        else
          render :action => :reset
        end
      end
    end

    def list
      @users = User.find(:all)
    end

    def destroy
      @user = User.find(params[:id])
      unless @user.destroy
        flash[:error] = "Error Deleting User"
        redirect_to :action => 'list'
      end
    end
end
