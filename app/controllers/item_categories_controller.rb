class ItemCategoriesController < ApplicationController
  before_filter :admin_required
  
  def index
	# fetch all item categories
    @item_categories = ItemCategory.all
  end
  
  def new
	# new item category
    @item_category = ItemCategory.new
  end
  
  def create
	# creates a new item category in the database
    @item_category = ItemCategory.new(params[:item_category])
    @item_category.save
  end
  
  def destroy
	# find the item category with the ID specified
    @item_category = ItemCategory.find(params[:id])

	# if it was not erased
	unless @item_category.destroy
		# show pop up regarding error 
		gflash :error => "Error Deleting Item Category"
		# redirect back the index page listing all categories
		redirect_to :action => 'index'
    end
  end
  
  def show
	# retrieve the item category with the ID specified
    @item_category = ItemCategory.find(params[:id])
	# get all the items for the category retrieved
    @items = @item_category.items
  end
  
  def edit
	# retrieve the item category with the ID specified
    @item_category = ItemCategory.find(params[:id])
  end
  
  def update
	# retrieve the item category with the ID specified
    @item_category = ItemCategory.find(params[:id])
	# update attributes depending on the parameters
    @item_category.update_attributes(params[:item_category])
	# write/save to the database
    @item_category.save
  end

end
