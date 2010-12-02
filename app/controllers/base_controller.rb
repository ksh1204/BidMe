class BaseController < ApplicationController

  def index
    @items = Item.search "", :page => params[:page], :per_page => 3, :conditions => {:closed => false}
  end
  
  def all_users
    @users = User.all
  end


end
