desc "Ending auction"
task :close_auction => :environment do
  auction_ticker = AuctionTicker.new(ENV["ITEM_ID"])
  AuctionClose.new(auction_ticker)
  auction_ticker.run
end