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
      redirect_back_or_default('/')
      gflash :success => "Thanks for posting!"
    else      
      gflash :error  => "Post failed. Try again."
      render :action => 'new'
    end
  end
  
  def search
    @items = Item.search params[:q], :page => 1, :per_page => 20
  end
  
  def show
    @item = Item.find(params[:id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    @end_date = Time.parse(@item.created_at.to_s)+@item.time_limit
  end
  
  def bin_check
    @bin = session[:bin_checked] = !session[:bin_checked]
  end
end
