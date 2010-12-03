class AdminController < ApplicationController
  before_filter :admin_required
  def index
  end
  
  def manage_users
	# gather all users
    @users = User.all
  end
  
  def manage_item_categories
	# gather all categories
    @categories = ItemCategory.all
  end
  
  def manage_auctions
	# gather all auctions	
	@items = Item.all
  end
  
  def ban_user
	# find user with id specified
    @user = User.find(params[:id])
	# update that user's property :is_banned to TRUE
    @user.update_attribute(:is_banned,'true')
	# show pop up flash regarding user banning
    gflash :success => "#{@user.login} is banned!"
	# mail the user regarding ban
    UserMailer.deliver_ban_notification(@user)
	# redirect page back to the user's profile page
    redirect_to :controller => 'users', :action => 'profile', :username => @user.login
  end
  
  def unban_user
	# find user with id specified
    @user = User.find(params[:id])
	# update that user's property :is_banned to FALSE
    @user.update_attribute(:is_banned,'false')
	# show pop up flash regarding user banning
    gflash :success => "#{@user.login} is no longer banned!"
	# mail the user regarding unban
    UserMailer.deliver_unban_notification(@user)
	# redirect page back to the user's profile page
    redirect_to :controller => 'users', :action => 'profile', :username => @user.login
  end

  def stop
	# find auction to stop using id in the database
	@item = Item.find(params[:id])
	# find all the people who are watching this item
	@watchers = Watch.find(:all, :conditions => { :item_id => @item.id } )
	# close the auction
    @item.update_attribute(:closed,true)
	# change closed status of the auction to TRUE, i.e. it is now closed
    @item.update_attribute(:status,true)
	# find all bids for this item
    @bids = Bid.find(:all, :conditions => {:item_id => @item.id}, :order => "price DESC")
    
	# automatically replace the html to show the auction is now closed using ajax so
	# refreshing the page is not necessary
	render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :show_item_time, "Auction is closed now!"
            page.replace_html :bid_id, ""
            page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
	end

	# since the auction is now closed, get rid of all the watchers
	# for this item
	for @watcher in @watchers
		@watcher.destroy
	end

	# refund the highest bidder his/her money since the auction has been stopped    
	if @bids.count > 0
        @highest = @bids.first
        @highest_bidder = @highest.bidder
        @highest_bidder.money += @highest.item.price
	end

	# redirect page back to the auction page
    redirect_to :controller => 'items', :action => 'show', :id => @item.id
  end
  
  def delete_comment
    @comment = UserComment.find(params[:id])
    @comment.destroy
  end
end
