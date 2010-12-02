#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'eBayAPI'

#
# Example of GetSuggestedCategories call
#

# Put your credentials in this file
load('myCredentials.rb')

# Create new eBay caller object.  Omit last argument to use live platform.
eBay = EBay::API.new($authToken, $devId, $appId, $certId, :sandbox => true) 
# Call "GetSuggestedCategories"
resp=eBay.GetSearchResults(:Query => 'iphone')
puts "*********************************************************************************"



resp.searchResultItemArray.each do | r |
puts r.item.sellingStatus.currentPrice
puts r.item.title
puts r.item.listingDetails.startTime
puts r.item.listingDetails.endTime
puts
end
