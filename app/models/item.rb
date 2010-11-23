class Item < ActiveRecord::Base
  has_one :user_item
  has_one :user, :through => :user_item
  belongs_to :item_category
  has_many :transactions
  has_many :watches
  has_many :watchers, :through => :watches
  
  has_many :bids
  has_many :bidders, :through => :bids
  
  has_attached_file :item_photo, :default_url => "/images/default.png",
  :styles => {
    :thumb=> "50x50#",
    :small  => "150x150>",
    :medium => "300x300>",
    :large =>   "400x400>" }
    
  validates_presence_of     :name
  validates_length_of       :name,    :within => 3..40
  
  validates_presence_of     :description
  validates_length_of       :description,    :within => 3..500
  
  validates_presence_of     :item_category_id
  
  validates_presence_of     :start_price
  
  validates_presence_of     :time_limit
    
  attr_accessible :name, :description, :bin, :bin_price, :item_category_id, :item_photo, :start_price, :time_limit, :current_price
  
  define_index do
    indexes :name, :sortable => true
    set_property :delta => true
  end

end
