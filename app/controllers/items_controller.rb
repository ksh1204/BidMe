class ItemsController < ApplicationController
  before_filter :login_required
  
  def index
  end
  
  def new
    @item = Item.new
    session[:bin_checked] = false
  end
  
  def create
    @item = Item.new(params[:item])
    success = @item && @item.save
    if success && @item.errors.empty?
      @item.time_limit += @item.time_limit_hours*3600+@item.time_limit_minutes*60
      @user_item = current_user.user_items.build(:item_id => @item.id)
      @user_item.save
      session[:bin_checked] = nil
      system "rake close_auction ITEM_ID=#{@item.id} &"
      #AuctionWorker.async_end_auction(:item_id => @item.id)
      gflash :success => "Thanks for posting!"
      redirect_to :action => 'show', :id => @item.id
    else      
      gflash :error  => "Post failed. Try again."
      render :action => 'new'
    end
  end
  
  def search
        @items = Item.search params[:q], :page => params[:page], :per_page => 15, :conditions => {:closed => false}
        
        if @items.first && params[:q] != ""
        
          # Create new eBay caller object.  Omit last argument to use live platform.
          eBay = EBay::API.new($authToken, $devId, $appId, $certId, :sandbox => true) 
          # Call "GetSearchResults"
          resp=eBay.GetSearchResults(:Query => params[:q])
          @price_array = Array.new
  #(r.item.itemID,r.item.title,r.item.country,r.item.listingDetails.viewItemURL,r.item.sellingStatus.currentPrice)
          resp.searchResultItemArray.each do | r |
            @price_array << r.item.sellingStatus.currentPrice
          end
        
          #@ebay_items = EbayItem.find(:all, :conditions => {:keyword => params[:q]})
        end
  end
  
  def list_ebay_items
    @price_array = params[:ebay]
  end
  
  def show
    @item = Item.find(params[:id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    if @diff.to_f <= 0
      @item.update_attribute(:closed,true)
    end
    @bids = @item.bids
    @highest_bid = nil
    if @bids.count > 0
      @highest_bid = @bids.sort_by {|b| -b.price}.first
    end
    
  end
  
  def twitter
    oauth = Twitter::OAuth.new($cons_token, $cons_secret)
    oauth.authorize_from_access($access_token, $access_token_secret)

    client = Twitter::Base.new(oauth)
    client.friends_timeline.each  { |tweet| puts tweet.inspect }
    client.user_timeline.each     { |tweet| puts tweet.inspect }
    client.replies.each           { |tweet| puts tweet.inspect }

    client.update('Heeeyyyyoooo from Twitter Gem!')
  end
   

  def bin_check
    @bin = session[:bin_checked] = !session[:bin_checked]
  end
  
  def end_auction
    @item = Item.find(params[:id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
	@watchers = Watch.find(:all, :conditions => { :item_id => @item.id } )
    if @diff <= 0 && !@item.status 
      @item.update_attribute(:closed,true)
      @item.update_attribute(:status,true)
      @bids = Bid.find(:all, :conditions => {:item_id => @item.id}, :order => "price DESC")
      @admin = User.find_by_login("admin")
    
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
        @message = @admin.sent_messages.build(:receiver_id => @highest.bidder_id, :description => "Congratulations! You won the item <a href='/items/#{@highest.item.id}'>#{@highest.item.name}</a>")
        @sold_message = @admin.sent_messages.build(:receiver_id => @item.user.id, :description => "Congratulations! You sold the item <a href='/items/#{@highest.item.id}'>#{@highest.item.name}</a>")
        @message.save
        @sold_message.save
        @unread_messages = Message.find(:all, :conditions => {:receiver_id => @highest.bidder_id, :unread => true})
        @seller_unread_messages = Message.find(:all, :conditions => {:receiver_id => @item.user.id, :unread => true})
        @seller_unread = @seller_unread_messages.count
        @num_unread = @unread_messages.count
        render :juggernaut => {:type => :send_to_client, :client_id => @highest.bidder_id} do |page|
          page.insert_html :top, :main_content, :partial => 'base/win_auction_message', :object => @highest
          page.visual_effect :fade, :no_message, :duration => 2
          page.replace :inbox_link, :partial => '/users/update_inbox_link', :object => @num_unread
          page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
          page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
        end
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
