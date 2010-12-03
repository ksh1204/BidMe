class ItemsController < ApplicationController
  before_filter :login_required
  
  def index
  end
  
	# Initializing the item object
	def new
		@item = Item.new
		session[:bin_checked] = false
	end
  
	# Create a new item object
  def create
		# create a new item with the parameters provided
    @item = Item.new(params[:item])
		# if creation of @item is successful and if it was written to the database successfully
    success = @item && @item.save

		# if success is TRUE and if there were no errors
    if success && @item.errors.empty?
			# calculate the time when it ends depending on the hours+minutes+seconds provided 
      @item.update_attribute(:time_limit, @item.time_limit+@item.time_limit_hours*3600+@item.time_limit_minutes*60)
			# save this item as the current user's user_item
      @user_item = current_user.user_items.build(:item_id => @item.id)
      @user_item.save
			# destroy the session that holds the bin check
      session[:bin_checked] = nil
			# start background process regarding auction close and sending emails
      system "rake close_auction ITEM_ID=#{@item.id} &"
      
			
      gflash :success => "Thanks for posting!"
      redirect_to :action => 'show', :id => @item.id
    else      
      gflash :error  => "Post failed. Try again."
      render :action => 'new'
    end
  end

	# Search function
  def search
		# search for items that are not closed according to ":q"
		@items = Item.search params[:q], :page => params[:page], :per_page => 15, :conditions => {:closed => false}
        
		# if search box is not empty, i.e. user actually searched for something
		# do eBay stuff
		if @items.first && params[:q] != ""
			# Create new eBay caller object.  Omit last argument to use live platform.
      eBay = EBay::API.new($authToken, $devId, $appId, $certId, :sandbox => true) 
      # Call "GetSearchResults"
      resp=eBay.GetSearchResults(:Query => params[:q])
      @price_array = Array.new
      resp.searchResultItemArray.each do | r |
	      @price_array << r.item.sellingStatus.currentPrice
			end
		end
  end

	# Function to list eBay items
  def list_ebay_items
    @price_array = params[:ebay]
  end

	# Show item
  def show
		# retrieve item/auction with ID provided
    @item = Item.find(params[:id])
		# determine time difference, with respespect to when auction started
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc

		# if no more time
    if @diff.to_f <= 0
			# auction is now closed
      @item.update_attribute(:closed,true)
    end

		# retrieve all bids for this item
    @bids = @item.bids
    @highest_bid = nil

		# if there were bids for the item
    if @bids.count > 0
			# get the highest one
      @highest_bid = @bids.sort_by {|b| -b.price}.first
    end
  end
   
	# For the BIN checkbox
  def bin_check
    @bin = session[:bin_checked] = !session[:bin_checked]
  end

	# Function to end an auction
  def end_auction
		
		# retrieve item/auction with ID provided
    @item = Item.find(params[:id])
		
		# determine time difference, with respespect to when auction started
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
		# retrieve all users watching this item
	  @watchers = Watch.find(:all, :conditions => { :item_id => @item.id } )

		# there is no time left and item/auction has not yet been closed
    if @diff <= 0 && !@item.status
			# close the auction
      @item.update_attribute(:closed,true)
      @item.update_attribute(:status,true)
			
			# find all bids for this auction/item
      @bids = Bid.find(:all, :conditions => {:item_id => @item.id}, :order => "price DESC")
			# get admin user
      @admin = User.find_by_login("admin")

			# automatically replace the html to show the auction is now closed using ajax so
			# refreshing the page is not necessary
      render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :show_item_time, "Auction is closed now!"
            page.replace_html :bid_id, ""
            page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
			end

			# since the auction is now closed, get rid of all the watchers
			# for this item, if there are any
			for @watcher in @watchers
				@watcher.destroy
			end
    
			# this bif IF block is the logic for all the transactions that has to be done
			# when an auction ends; auction winner, seller, sending messages to appropriate
			# users, etc.
			if @bids.count > 0
		  	@highest = @bids.first

				# send message to winner
		    @message = @admin.sent_messages.build(:receiver_id => @highest.bidder_id, 
									 :description => "Congratulations! You won the item <a href='/items/#{@highest.item.id}'>#{@highest.item.name}</a>")

				# send message to seller
		    @sold_message = @admin.sent_messages.build(:receiver_id => @item.user.id, 
												:description => "Congratulations! You sold the item <a href='/items/#{@highest.item.id}'>#{@highest.item.name}</a>")
		    @message.save
		    @sold_message.save

				# retrieve all unread messages of the highest bidder
		    @unread_messages = Message.find(:all, :conditions => {:receiver_id => @highest.bidder_id, :unread => true})
				# retrieve all unread messages of the seller
		    @seller_unread_messages = Message.find(:all, :conditions => {:receiver_id => @item.user.id, :unread => true})

				# count them
		    @seller_unread = @seller_unread_messages.count
		    @num_unread = @unread_messages.count

				# automatically replace the html to show the new message and inbox unread message number using ajax so
				# refreshing the page is not necessary
		    render :juggernaut => {:type => :send_to_client, :client_id => @highest.bidder_id} do |page|
		      page.insert_html :top, :main_content, :partial => 'base/win_auction_message', :object => @highest
		      page.visual_effect :fade, :no_message, :duration => 2
		      page.replace :inbox_link, :partial => '/users/update_inbox_link', :object => @num_unread
		      page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
		      page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
		    end

				# automatically replace the html to show the new message and inbox unread message number using ajax so
				# refreshing the page is not necessary
		    render :juggernaut => {:type => :send_to_client, :client_id => @item.user.id} do |page|
		      page.insert_html :top, :main_content, :partial => 'base/sold_item_message', :object => @highest
		      page.visual_effect :fade, :no_message, :duration => 2
		      page.replace :inbox_link, :partial => '/users/update_inbox_link', :object => @seller_unread
		      page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @sold_message
		      page.visual_effect :highlight, "message_#{@sold_message.id}", :duration => 5
		    end
		  end
	  end
    redirect_to :action => 'show', :id => @item.id
	end
  
end
