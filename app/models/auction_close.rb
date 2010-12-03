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
  	    seller = user
  	    buyer = highest_bid.bidder
  	    UserMailer.deliver_win_auction_notification(buyer,transaction)
  	    UserMailer.deliver_sold_item_notification(seller,transaction)
      end
    end
  end
