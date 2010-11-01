class AdminController < ApplicationController
  before_filter :admin_required
  def index
  end
  
  def manage_users
    @users = User.all
  end
  
  def manage_item_categories
    @categories = ItemCategory.all
  end
  
  def manage_auctions
  end
  
  def ban_user
    @user = User.find(params[:id])
    @user.update_attribute(:is_banned,'true')
    gflash :success => "#{@user.login} is banned!"
    UserMailer.deliver_ban_notification(@user)
    redirect_to :controller => 'users', :action => 'profile', :username => @user.login
  end
  
  def unban_user
    @user = User.find(params[:id])
    @user.update_attribute(:is_banned,'false')
    gflash :success => "#{@user.login} is no longer banned!"
    UserMailer.deliver_unban_notification(@user)
    redirect_to :controller => 'users', :action => 'profile', :username => @user.login
  end
end
