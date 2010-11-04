class AuctionClose          ### An abstract observer of AuctionTicker objects.
    def initialize(ticker)
      ticker.add_observer(self)
    end
    
    def update(item)
      item.update_attribute(:closed,true)
    end
  end