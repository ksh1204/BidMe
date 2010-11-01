class ItemCategoriesController < ApplicationController
  before_filter :admin_required
  
  def index
    @item_categories = ItemCategory.all
  end
  
  def new
    @item_category = ItemCategory.new
  end
  
  def create
    @item_category = ItemCategory.new(params[:item_category])
    @item_category.save
  end
  
  def destroy
    @item_category = ItemCategory.find(params[:id])
    unless @item_category.destroy
      gflash :error => "Error Deleting Item Category"
      redirect_to :action => 'index'
    end
  end
  
  def show
    @item_category = ItemCategory.find(params[:id])
    @items = @item_category.items
  end
  
  def edit
    @item_category = ItemCategory.find(params[:id])
  end
  
  def update
    @item_category = ItemCategory.find(params[:id])
    @item_category.update_attributes(params[:item_category])
    @item_category.save
  end
end
