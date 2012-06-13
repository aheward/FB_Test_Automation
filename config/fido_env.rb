require '../config/env'
require '../lib/fido/fido'
require '../lib/fido/fb-modules'
require '../lib/fido/page_classes'

include CrawlerMethods

@fido = Fido.new
login_page = @fido.page
@browser = @fido.browser
@accounts_index = login_page.log_in(@fido.user_name, @fido.password)