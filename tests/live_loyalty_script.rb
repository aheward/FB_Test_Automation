=begin

Tests the Loyalty Campaign on Production

Things to do:
- Still need to add a click of the loyalty imp and then 
a success after that, so as to test the remittance
value.

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

test_data = $browser.table(:class => "confluenceTable", :index => 5).to_a

test_data.shuffle!
client_name = []
test_address = []

test_data.each_index do |x|
	client_name << test_data[x][0]
	test_address << test_data[x][1]
end

puts "Testing: #{@config.test_site}"
puts ""
puts "============================="
puts "Loyalty tests"
puts "============================="
puts ""
puts "Sites checked:"
puts client_name

conversion_type_array = [ 
"dtc", 
"vtc", 
"ctc"
]

iteration = 1

# beginning of iteration for sites/campaigns...
client_name.each_index do | index |
  
	unless iteration%17 == 0
		# Go to Fido...
		$browser.goto("http://#{@config.test_site}/fido/")
		# Log in to site...
		fido_log_in($browser, @config.fido_username, @config.fido_password)
	end
	
	# Every 17th iteration through this, restart the browser...
	iteration += 1
	if iteration%17 == 0
		$browser.close
		sleep(5)
		$browser = Watir::Browser.start("http://#{@config.test_site}/serve/")
		fido_log_in($browser, @config.fido_username, @config.fido_password)
	end	

	# Navigate to Client Site in Fido...
	open_fido_site($browser, client_name[index])

	site = Site.new($browser)

	puts ""
	puts ""
	puts "Testing #{site.name}. Loyalty campaign."
	puts "--------------------------------------------------"
	puts "Site ID: #{site.id}"

	conversion = conversion_type_array[rand(3)]
	
	# Go to Loyalty Campaign page in Fido
	$browser.link(:text, "loyalty.campaign").click
	
	campaign = Campaign.new($browser)

	puts "Campaign ID: #{campaign.id}"
	puts "CPM: #{site.cpm}"

	# Go to Network AdTag page in Fido...
	$browser.link(:id, "ExternalLink_1_0").click

	$browser.window(:title, "FetchBack Campaign").close
	$browser.window(:title, "FetchBack NetworkAdTag").use	

	ad_tag = AdTag.new($browser)
	
	puts "Ad Tag ID: #{ad_tag.id}"
	puts "Conversion type tested: #{conversion.upcase}"
	
	# ==================
	# Actual tests all go below...
	# ==================

	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff =  calc_offset_time(@config.offset, 10)
	$browser.goto(test_address[index])
	sleep(1)	# now we have been pixeled!
	
	# Get contents of pixel log...
	pixel = get_log(@config.pixel_log)

	unless conversion == "dtc"
		imp_cutoff =  calc_offset_time(@config.offset, 10)
		$browser.goto(tagify(ad_tag.ids[rand(ad_tag.ids.length)]))
		sleep 2
	end
	
	if conversion == "ctc" # If we're going for a CTC...
		# then "click" 
		click = clicktrack($browser, test_address[index])
		puts "Clicktracking link: #{click}"
		$browser.goto(click)
	end

	# If CTC or VTC, get impression log data...
	unless conversion == "dtc"

		imp = get_log(@config.imp_log)
		
	end

	# Success
	success_cutoff =  calc_offset_time(@config.offset, 15)
	$browser.goto(campaign.pdc_success_pixel) # note that this is the last element of the pdc array
	sleep 1

	# Get new Pixel log info...

	success_pixel = get_log(@config.pixel_log)

	# Collect info from Conversion log...
	conversion_cutoff = pixel_cutoff
	
	conversion_log = get_log(@config.conversion_log)

	
	# Go back to an impression...
	$browser.goto(tagify(ad_tag.ids[rand(ad_tag.ids.length)]))

	sleep 2
	
	# Loyalty campaign impression log...
	loyalty_cutoff =  calc_offset_time(@config.offset, 15)

	loyalty_log = get_log(@config.imp_log)
	
	#Report Results...
	puts ""
	puts "Pixel log, prior to impression or success. Loyalty campaign:"
	puts filtrate(pixel, pixel_cutoff)
	
	unless conversion == "dtc"
		puts ""
		puts "Served a random impression for the client:"
		puts filtrate(imp, imp_cutoff)
	end

	puts ""
	puts "Success pixel:"
	success_array = filtrate(success_pixel, success_cutoff)
	success_array.delete_if  { | lines | lines.to_s.include?("success") == false }
	puts success_array
	
	puts ""
	puts "#{conversion.upcase} conversion:"
	puts (filtrate(conversion_log, conversion_cutoff))[-1]
	
	puts ""	
	ids = campaign.active_creative_ids.join(", ")
	puts "Loyalty impression (creative should be one of these IDs): #{ids}"
	puts filtrate(loyalty_log, loyalty_cutoff)
	puts "_____________________________________"
	
end 
# We're done!
