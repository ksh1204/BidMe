class ItemObserver < ActiveRecord::Observer
  def after_end_auction(item)
    highest_bid = item.bids.sort_by {|b| -b.price}.first
    buyer = highest_bid.buyer_id
    price = highest_bid.price

    user = item.user
    user.money = user.money + price
    user.save

    seller = item.user
    transaction = seller.build(:buyer_id => buyer.id, :price => price, :item_id => item.id)
    transaction.save
  end
end
