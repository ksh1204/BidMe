class ItemsController < ApplicationController
  before_filter :login_required
  def index
  end
  
  def new
    @item = Item.new
  end
  
  def create
    @item = Item.new(params[:item])
    success = @item && @item.save
    if success && @item.errors.empty?
      current_user.user_items.build(:item_id => @item.id)
      redirect_back_or_default('/')
      gflash :success => "Thanks for posting!"
    else
      gflash :error  => "Post failed. Try again."
      render :action => 'new'
    end
  end
  
  def search
  end
  
  def show
  end
end
