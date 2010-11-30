class AuctionClose          ### An abstract observer of AuctionTicker objects.
    def initialize(ticker)
      ticker.add_observer(self)
    end
    
    def update(item)
      item.update_attribute(:closed,true)
      highest_bid = item.bids.sort_by {|b| -b.price}.first
      if highest_bid
	    bidder_id = highest_bid.bidder_id
	    price = highest_bid.price
	    user = item.user
	    user.money = user.money + price
	    user.save
	    transaction = Transaction.new
	    transaction.seller_id = user.id
	    transaction.buyer_id = bidder_id
	    transaction.item_id = item.id
	    transaction.price = price
	    transaction.save
	    render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :highest_bid, "Auction is closed now!"
            page.replace_html :bid_id, ""
            page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
            page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
            page.visual_effect :highlight, "item_time_#{@item.id}", :duration => 5
      end
      end
    end
  end
