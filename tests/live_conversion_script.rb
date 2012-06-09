=begin

On PRODUCTION, This script tests the DTC, CTC, and VTC conversions 
for the landing, dynamic, and keyword campaign types.

Things to do:
- Improve using RSpec and Test/Unit (this is a medium-term goal)
- Add better logic for campaign and ad tag selection process... maybe

=end
#!/usr/bin/env ruby
require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido-classes'

include LogManipulators
include Randomizers
include FidoTamers

@config = FBConfig.new(:prod)

@browser = @config.browser
@browser.goto(@config.data_wiki)

if @browser.button(:name, "login").exist?
	unless @browser.text_field(:id, "os_username").value.include?(@config.confluence_username)
		@browser.text_field(:id, "os_username").set(@config.confluence_username)
		@browser.text_field(:id, "os_password").focus
		@browser.text_field(:id, "os_password").set(@config.confluence_password)
	end	
	@browser.button(:name, "login").click
end

test_data = @browser.table(:class => "confluenceTable", :index => 4).to_a
test_data.shuffle!
client_name = []
campaign_name = []
test_address = []

test_data.each_index do |x|
	client_name << test_data[x][0]
	campaign_name << test_data[x][1]
	test_address << test_data[x][2]
end


close_browser(@browser)
sleep(4)

puts "Testing: #{@config.test_site}"
puts ""
puts "============================="
puts "DTC, CTC, and VTC tests"
puts "============================="
puts ""
puts "Sites checked:"
puts client_name

conversion_type = [ 
"dtc", 
"vtc", 
"ctc"
]
conversion_count = (conversion_type.length - 1)

client_name.each_index do | index |
	
	# Open Browser to Fido...
	@browser = Watir::Browser.start("http://#{@config.test_site}/fido/")
		
	# Log in to site...
	fido_log_in(@browser, @config.fido_username, @config.fido_password)

	# Navigate to Client Site in Fido...
	open_fido_site(@browser, client_name[index])  

	#Get Site and Campaign Variables...

	site = Site.new(@browser)

	@browser.link(:text, campaign_name[index]).click 

	campaign = Campaign.new(@browser)

	puts ""
	puts ""
	puts "Testing #{site.name}, #{campaign.name.capitalize} campaign."
	puts "--------------------------------------------------"
	puts "Site ID: #{site.id}  Campaign ID: #{campaign.id}"

	# Go to Network AdTag page in Fido...
	@browser.link(:id, "ExternalLink_1_0").click
	
	@browser.window(:title, "FetchBack Campaign").close
	@browser.window(:title, "FetchBack NetworkAdTag").use		
	
	ad_tag = AdTag.new(@browser)

	puts ""
	puts "Network: #{ad_tag.network}  ID: #{ad_tag.id}"
	puts "Count of active ad tags: #{ad_tag.ids.length}"

	puts "Ad Tag IDS: #{ad_tag.ids}"
	puts "Creative IDS: #{campaign.active_creative_ids}"
	
	@browser.close

	# Conversions iterator...
	0.upto(conversion_count) do | conversion_index |
		
		# Go to the page so as to get pixeled by the desired campaign...
		@browser = Watir::Browser.start(test_address[index])  
		puts "Pixel page: #{test_address[index]}"
		sleep(1)	# now we have been pixeled!

		# Get contents of pixel log...
		pixel_cutoff = calc_offset_time(@config.offset, 9)
		
		pixel = get_log(@config.pixel_log)

		unless conversion_type[conversion_index] == "dtc"
			0.upto(ad_tag.ids.length - 1) do |x|
				imp_link = tagify(ad_tag.ids[x])
				@browser.goto(imp_link)
				puts "Impression link: #{imp_link}"
				sleep 2
			end	
		end
	
		if conversion_type[conversion_index] == "ctc" # If we're going for a CTC...
			# then "click" unless it's a doubleclick site...
			click = clicktrack(@browser, test_address[index])
			puts "Clicktracking link: #{click}"
			@browser.goto(click)
		end

		# If CTC or VTC, get impression log data...
		unless conversion_type[conversion_index] == "dtc"
			imp_cutoff = calc_offset_time(@config.offset, 15)
			
			imp = get_log(@config.imp_log)
		end

		# Success
		success_cutoff = calc_offset_time(@config.offset, 10)
		@browser.goto(campaign.pdc_success_pixel)
		puts "Success link: #{campaign.pdc_success_pixel}"
		
		success_pixel = get_log(@config.pixel_log)
		
		# Collect info from Conversion log...
		conversion_cutoff = pixel_cutoff
		
		conversion_log =get_log(@config.conversion_log)
		
		@browser.close
	
		puts ""
		puts "Pixel log, prior to impression or success. #{campaign.name.capitalize} campaign:"
		puts filtrate(pixel, pixel_cutoff)
		imp_hash = {}
		unless conversion_type[conversion_index] == "dtc"
			puts ""
			puts "Served #{ad_tag.ids.length} impressions:"
			imp_array = filtrate(imp, imp_cutoff)
			imp_lines = imp_array.find { | line | line =~ /\timp\t/ }
			puts imp_lines
			begin
				imp_hash = split_log(imp_lines.chomp, "impression")
			rescue NoMethodError
				puts "--Something's up with the impression served."
				puts "--I'm guessing it's because of a mismatch"
				puts "--between the sites.db and the test machine."
				puts ""
				puts "--You might try running a #{conversion_type[conversion_index]} one-off test"
				puts "--using the following data..."
				puts "Site name: #{hash["site_name"]}"
				puts "Campaign name: #{hash["campaign_name"]}"
				puts "Test URL: #{hash[:url]}"
				puts
				puts "--\t\tMoving on to next test..."
				next
			end
		end
	
		puts ""
		puts "Success pixel:"
		
		success_array = filtrate(success_pixel, success_cutoff)
		success_array.delete_if  { | lines | lines.to_s.include?("success") == false }
		success_pixel_hash = split_log(success_array[-1].chomp, "pixel")
		parse_pixel(success_pixel_hash, site.id, campaign.id, campaign.name, ad_tag.associated_account)
		
		puts success_array
		puts ""
		puts "#{conversion_type[conversion_index].upcase} conversion:"
		conv = (filtrate(conversion_log, conversion_cutoff))[-1]
		puts conv
		conversion_hash = split_log(conv.chomp, "conversion")

		parse_conversion(conversion_hash, conversion_type[conversion_index], success_pixel_hash, imp_hash, campaign.id, site.id)
		puts "_____________________________________"
	end 
# We're done!
end 

