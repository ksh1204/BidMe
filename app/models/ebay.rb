require 'net/http'

def self.init(keyword)
"http://svcs.ebay.com/services/search/FindingService/v1?OPERATION-NAME=findItemsByKeywords
   &SERVICE-VERSION=1.0.0
   &SECURITY-APPNAME=UBCaea01f-5cee-4e08-85c5-15a6bf15751
   &RESPONSE-DATA-FORMAT=XML
   &REST-PAYLOAD
   &keywords=keyword"
end