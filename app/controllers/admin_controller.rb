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
	@items = Item.all
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

  def stop
      @item = Item.find(params[:id])
	  @watchers = Watch.find(:all, :conditions => { :item_id => @item.id } )
      @item.update_attribute(:closed,true)
      @item.update_attribute(:status,true)
      @bids = Bid.find(:all, :conditions => {:item_id => @item.id}, :order => "price DESC")
    
      render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :show_item_time, "Auction is closed now!"
            page.replace_html :bid_id, ""
            page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
      end

  	  for @watcher in @watchers
  		  @watcher.destroy
  	  end
    
      if @bids.count > 0
        @highest = @bids.first
        @highest_bidder = @highest.bidder
        @highest_bidder.money += @highest.item.price
      end

    redirect_to :controller => 'items', :action => 'show', :id => @item.id
  end
  
  def delete_comment
    @comment = UserComment.find(params[:id])
    @comment.destroy
  end
end
