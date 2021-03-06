=begin

Tests Merit values at specified cookie offsets.

Things to do:
- This will need updating when Nikolas finally gets around to making the
cookie page
- At some point it will need to be refactored with RSpec and Test/Unit stuff

=end
#!/usr/bin/env ruby
require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido-classes'
include LogManipulators
include Randomizers
include FidoTamers

@config = FBConfig.new(:prod)

$browser = @config.browser
$browser.goto(@config.data_wiki)
if $browser.button(:name, "login").exist?
  unless $browser.text_field(:id, "os_username").value.include?(@config.confluence_username)
    $browser.text_field(:id, "os_username").set(@config.confluence_username)
    $browser.text_field(:id, "os_password").focus
    $browser.text_field(:id, "os_password").set(@config.confluence_password)
  end
  $browser.button(:name, "login").click
end

test_data = $browser.table(:class => "confluenceTable", :index => 7).to_a

test_data.shuffle!
client_name = []
campaign_name = []
test_address = []

test_data.each_index do |x|
	client_name << test_data[x][0]
	campaign_name << test_data[x][1]
	test_address << test_data[x][2]
end

puts "Testing: #{@config.test_site}"
puts ""
puts "============================="
puts "VTC Merit tests"
puts "============================="
puts client_name

merit_offset = ["2592000","691200","604700","259200","259100","86400","86240"]

conversion = "vtc"

# beginning of iteration for sites/campaigns...
client_name.each_index do | index |

	# Open Browser to Fido...
	$browser.goto("http://#{@config.test_site}/fido/")	#Open FIDO to get all link variables

	# Log in to site...
  fido_log_in($browser, @config.fido_username, @config.fido_password)

	# Navigate to Client Site in Fido...
	active = open_fido_site($browser, client_name[index])	# Client link
	
	next if active == false
	
	site = Site.new($browser)

	puts ""
	puts "Testing #{client_name[index]}, #{campaign_name[index]} campaign."
	puts "--------------------------------------------------"
	puts "Site ID: #{site.id}"

	merit30 = 41
	merit7 = 52
	merit3 = 63
	merit1 = 100

	# Go to Campaign page in Fido...
	$browser.link(:text, campaign_name[index]).click

	campaign = Campaign.new($browser)

	puts "Campaign ID: #{campaign.id}"
	puts "Conversion window: #{site.conversion_window}"

	# Go to Network AdTag page in Fido...
	# Fix this code later!
	if $browser.link(:id, "ExternalLink_1_0").exist?
		$browser.link(:id, "ExternalLink_1_0").click
	else
		$browser.link(:id, "ExternalLink_3_0").click
	end
	
	$browser.window(:title, "FetchBack Campaign").close
	$browser.window(:title, "FetchBack NetworkAdTag").use	

	ad_tag = AdTag.new($browser)

	puts "Ad Tag ID: #{ad_tag.id}"

	# ==================
	# Actual tests all go below...
	# ==================

	$browser.goto("https://rptdev.fetchback.com/hub/xfb/testing/cookie_edit.php")
		
	$browser.text_field(:id, "uid").set(%|99|)
	$browser.button(:id, "control").click

	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff =  calc_offset_time(@config.offset, 5)
	$browser.goto(test_address[index])
	sleep(1)	# now we have been pixeled!
	
	puts "Pixel link: " + test_address[index]
	
	# Get contents of pixel log...
	
	pixel = get_log(@config.pixel_log)
	
	tag = ad_tag.ids[rand(ad_tag.ids.length)]
	imp_link = tagify(tag)
	
	imp_cutoff =  calc_offset_time(@config.offset, 10)
	$browser.goto(imp_link)
	puts imp_link
	sleep(2.5)
	
	raw_imp_log = get_log(@config.imp_log)
	filtered_imp_log = filtrate(raw_imp_log, imp_cutoff)
	imp_hash = split_log(filtered_imp_log[-1].chomp, "impression")
	
	$browser.goto("https://rptdev.fetchback.com/hub/xfb/testing/cookie_edit.php")
	
	test_offset = merit_offset[rand(merit_offset.length)]
	
	puts "Offset time: " + test_offset
	
	$browser.text_field(:id, "networkAdTagId").set(imp_hash[:adtag_id])
	$browser.text_field(:id, "creativeId").set(imp_hash[:creative_id])
	$browser.text_field(:id, "offset").set(test_offset)
	$browser.button(:id, "merit").click

	# Success
	success_cutoff =  calc_offset_time(@config.offset, 5)
	$browser.goto(campaign.pdc_success_pixel) # note that this is the last element of the pdc array
	raw_success_pixel_log = get_log(@config.pixel_log)
	filtered_success_pixel_log = filtrate(raw_success_pixel_log, success_cutoff)
	filtered_success_pixel_log.delete_if  { | lines | lines.to_s.include?("success") == false }
	success_pixel_hash = split_log(filtered_success_pixel_log[-1].chomp, "pixel")

	# Collect info from Conversion log...
	conversion_cutoff = pixel_cutoff
	raw_conversion_log = get_log(@config.conversion_log)
	filtered_conversion_log = filtrate(raw_conversion_log, conversion_cutoff)
	conversion_hash = split_log(filtered_conversion_log[-1].chomp, "conversion")

	# Report results
	
	puts ""
	puts "Pixel log, prior to impression or success. #{campaign_name[index].capitalize} campaign:"
	puts filtrate(pixel, pixel_cutoff)

	puts ""
	puts "Served impression:"
	puts filtered_imp_log
	parse_impression(imp_hash, campaign.id, ad_tag.ids, ad_tag.cpm, site.cpc, @config.sites_db)

	puts ""
	puts "Success pixel:"
	puts filtered_success_pixel_log
	parse_pixel(success_pixel_hash, site.id.to_s, campaign.id.to_s, campaign.name, ad_tag.associated_account)
	
	puts "Conversion:"
	puts filtered_conversion_log[-1]
	parse_conversion(conversion_hash, "vtc", success_pixel_hash, imp_hash, campaign.id.to_s, site.id.to_s, merit30, merit7, merit3, merit1)
	
	puts "__________________________________"

end
# We're done!
