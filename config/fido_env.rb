require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido'

include Randomizers
include CrawlerMethods

@fido = Fido.new :rt
login_page = @fido.page
@browser = @fido.browser
@accounts_index = login_page.log_in(@fido.user_name, @fido.password)