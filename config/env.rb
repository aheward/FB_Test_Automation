$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../config'))
$:.unshift(File.join(File.dirname(__FILE__), '../lib/fido'))

require 'yaml'
require 'sqlite3'
require 'watir-webdriver'
require 'fileutils'
require 'cgi'
require 'openssl'
require 'open-uri'
require 'constants'
require 'config'
require 'blacklisted_sites'
require 'keyword_urls'
require 'fb_error_messages'
require 'cipher'
require 'generic_base_page'

include FetchBackConstants
