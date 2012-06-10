require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido'
require '../lib/randomizers'

include Randomizers
include CrawlerMethods

@fido = Fido.new
login_page = @fido.page
@browser = @fido.browser
@accounts_index = login_page.log_in(@fido.user_name, @fido.password)