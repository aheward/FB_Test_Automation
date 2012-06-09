test_site = "Avenue.com"
test_campaign = "Capri"

require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido-classes'

include FidoTamers

@config = FBConfig.new(:rt)

$browser = @config.browser

$browser.goto("http://#{$test_site}/fido/")
	
fido_log_in($browser, $username, $password)

open_fido_site($browser, test_site)

$browser.link(:text, test_campaign).click

campaign = Campaign.new($browser)

creative_names = []

campaign.creative_type.each do | key, value |

	if value == "Pop - 720x300"
		
		creative_names << key
		
	end	

end

$browser.link(:text, "Campaign Funnel (DQS)").click

dqs = DQS.new($browser)

dqs.enable.set

x = 0

(creative_names.length - 1).times do

	dqs.add(3)
	
end

3.upto(creative_names.length*3+2) do | x |
	
	dqs.show_hide(x)
	
end

creative_names.each do | name |

	x += 1
	dqs.type(x).select_value(x)
	dqs.description(x).set("Action #{x}")

	dqs.url_fragment(2*x).set("test#{x}")
	dqs.name(2*x).select(name)

end

dqs.submit