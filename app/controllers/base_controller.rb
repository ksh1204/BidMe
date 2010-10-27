class BaseController < ApplicationController

  def index
  end
  
  def all_users
    @users = User.all
  end


end
