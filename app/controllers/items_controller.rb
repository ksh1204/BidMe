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
   

  def bin_check
    @bin = session[:bin_checked] = !session[:bin_checked]
  end
  
  def end_auction
    @item = Item.find(params[:id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    @item.update_attribute(:closed,true)
    @bids = @item.bids
    @admin = User.find_by_login("admin")
    
    render :juggernaut => {:type => :send_to_all} do |page|
          page.replace_html :show_item_time, "Auction is closed now!"
          page.replace_html :bid_id, ""
          page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
    end
    
    if @bids.count > 0
      @highest = @bids.first
      @message = @admin.sent_messages.build(:receiver_id => @highest.bidder.id, :description => "Congratulations! You won the item <a href='/items/#{@highest.item.id}'>#{@highest.item.name}</a>")
      @message.save
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => @highest.bidder.id, :unread => true})
      @num_unread = @unread_messages.count
      render :juggernaut => {:type => :send_to_client, :client_id => @highest.bidder.id} do |page|
        page.insert_html :top, :main_content, :partial => 'base/win_auction_message', :object => @highest
        page.visual_effect :fade, :no_message, :duration => 2
        page.replace :inbox_link, :partial => '/users/update_inbox_link', :object => @num_unread
        page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
        page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
      end
    end

     render :action => 'show', :id => @item.id
end
end
