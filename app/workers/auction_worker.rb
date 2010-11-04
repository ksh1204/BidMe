class AuctionWorker < Workling::Base
  def end_auction(options)
    @item = Item.find(options[:item_id])
    @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    while @diff > 0
      @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
    end
    @item.update_attribute(:closed, true)
  end
end