#!/usr/bin/env ruby
# $Id: get_categories2.rb,v 1.3 2006/01/16 09:54:08 garrydolley Exp $

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'eBayAPI'

#
# Example of GetCategories call for eBay Motors
#

# Put your credentials in this file
load('myCredentials.rb')

# Create new eBay caller object.  Omit last argument to use live platform.
eBay = EBay::API.new($authToken, $devId, $appId, $certId, :sandbox => true, :site_id => 100)

# Call "GetCategories"
resp = eBay.GetCategories(:DetailLevel => 'ReturnAll', # Return all available info
                          :CategorySideID => 100,      # US eBay Motors Site 
                          :LevelLimit => 2)            # 2 Levels Deep

# Report results

puts "eBay Motors Top Level Categories (Cat. Version " + resp.categoryVersion + "):"
puts ""

resp.categoryArray.each do |cat|
  puts "  Category Name : " + cat.categoryName
  puts "  Category ID   : " + cat.categoryID
  puts "  Category Level: " + cat.categoryLevel.to_s
  puts "  Is Leaf?      : " + cat.leafCategory.to_s
  puts "  Parent ID     : " + cat.categoryParentID.to_s
  puts ""
end
