require 'fileutils'

ebay_config = File.dirname(__FILE__) + '/../../../config/ebay.yml'
FileUtils.cp File.dirname(__FILE__) + '/ebay.yml.tpl', ebay_config unless File.exist?(ebay_config)
puts IO.read(File.join(File.dirname(__FILE__), 'README'))