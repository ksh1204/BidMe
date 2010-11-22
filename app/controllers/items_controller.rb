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
    @items = Item.search params[:q], :page => params[:page], :per_page => 40
  end
  
  def show
    @item = Item.find(params[:id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    if @diff.to_f <= 0
      @item.update_attribute(:closed,true)
    end
    @end_date = Time.parse(@item.created_at.to_s)+@item.time_limit
    @bids = @item.bids
    @highest_bid = nil
    if @bids.count > 0
      @highest_bid = @bids.sort_by {|b| -b.price}.first
    end
    
  end
  
  def show_user_item
      @items = Item.find(:all)
  end

  def bin_check
    @bin = session[:bin_checked] = !session[:bin_checked]
  end
  
  def end_auction
    @item = Item.find(params[:id])
    @user = User.find(@item.user.id)
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    seller = @item.bids.sort_by {|b| -b.price}.first.bidder_id
    price = @item.bids.sort_by {|b| -b.price}.first
    @transaction = Transaction.new
    @transaction.buyer_id = @item.user.id
    @transaction.seller_id = seller
    @transaction.item_id = @item.id
    @transaction.price = price
    @transaction.save
    @user.money = @user.money + price
    @user.save
    @item.update_attribute(:closed,true)
    if !@item.closed
      if @diff <= 0
        render :juggernaut => {:type => :send_to_all} do |page|
          page.replace_html :highest_bid, "Auction is closed now!"
          page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
        end
      end
    end
    redirect_to :action => 'show', :id => @item.id
  end
end
