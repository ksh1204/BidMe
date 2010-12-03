require "observer"

  class AuctionTicker
    include Observable

    def initialize(item_id)
      @item = Item.find(item_id)
    end

    def run
      if !@item.closed
        loop do
          @diff = Time.parse(@item.created_at.to_s)+@item.time_limit-Time.now.utc
          if @item.closed
	            return
          end
          if @diff <= 0
            changed                 # notify observers
            notify_observers(@item)
          end
        end
      end
    end
  end
