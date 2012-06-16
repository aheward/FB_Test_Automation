require '../config/env'
require '../config/blacklisted_sites'
require '../config/keyword_urls'
require 'helpers/fb_error_messages'
require 'helpers/sql_commands'
require 'helpers/reporters'
require 'helpers/helpers'
require 'retargeting/cipher'
require 'retargeting/conversions'
require 'retargeting/cookies'
require 'retargeting/data_makers'
require 'retargeting/impressions'
require 'retargeting/logs'
require 'retargeting/pixel'

include FetchBackCookies
include Logs
include FBHelpers
include Pixel
include Impressions
include SQLCommands
include DataMakers
include Conversions
include Reporters

@config = FBConfig.new

@browser = Watir::Browser.new $browser
@browser.window.resize_to(1400,900)
