class Item < ActiveRecord::Base
  has_many :user_items
  belongs_to :item_category
  has_many :watches
  has_many :watchers, :through => :watches
  
  has_attached_file :item_photo, :default_url => "/images/default.png",
  :styles => {
    :thumb=> "50x50#",
    :small  => "150x150>",
    :medium => "300x300>",
    :large =>   "400x400>" }
    
  attr_accessible :name, :description, :bin, :bin_price, :item_category_id, :item_photo
  
  define_index do
    indexes :name, :sortable => true
  end
end
