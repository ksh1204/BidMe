class EbayItem < ActiveRecord::Base
  attr_accessible :ebay_id, :title, :country, :view_url, :price
  
end