class BaseController < ApplicationController

  # For the front page.
  # This function basically fetches all active auctions.
  def index
    @items = Item.search "", :page => params[:page], :per_page => 3, :conditions => {:closed => false}
  end


end
