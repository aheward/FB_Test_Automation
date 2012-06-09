=begin

On PRODUCTION, This script serves a bunch of imps without successing.

Things to do:
- fix the pixel log = nil garbage. That's not working right.

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

test_data = @browser.table(:class => "confluenceTable", :index => 12).to_a
test_data.shuffle!
client_name = []
campaign_name = []
test_address = []
test_data.each_index do |x|
	client_name << test_data[x][0]
	campaign_name << test_data[x][1]
	test_address << test_data[x][2]
end

client_name.each_index do | index |
	
	# Open Browser to Fido...
	@browser.goto("http://#{@config.test_site}/fido/")
		
	# Log in to site...
	fido_log_in(@browser, @config.fido_username, @config.fido_password)

	# Navigate to Client Site in Fido...
	active_site = open_fido_site(@browser, client_name[index])  

	if active_site != true
		puts "#{client_name[index]} can't be found. Is it Active?"
		next
	end	
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
	if @browser.link(:id, "ExternalLink_3_0").exist?
		@browser.link(:id, "ExternalLink_3_0").click
	else
		@browser.link(:id, "ExternalLink_1_0").click
	end
	
	@browser.window(:title, "FetchBack Campaign").close
	@browser.window(:title, "FetchBack NetworkAdTag").use	
	
	ad_tag = AdTag.new(@browser)

	puts ""
	puts "Network: #{ad_tag.network}  ID: #{ad_tag.id}"
	puts "Count of active ad tags: #{ad_tag.ids.length}"

	puts "Ad Tag IDS: #{ad_tag.ids}"
	puts "Creative IDS: #{campaign.active_creative_ids}"

	# Go to the page so as to get pixeled by the desired campaign...
	@browser.goto(test_address[index])  
	puts "Pixel page: #{test_address[index]}"
	sleep(1)	# now we have been pixeled!
	
	# Get contents of pixel log...
	pixel_cutoff = calc_offset_time(@config.offset, 10)
	
	pixel = get_log(@config.pixel_log)
	
	imp_cutoff = calc_offset_time(@config.offset, 5)
	0.upto(ad_tag.ids.length - 1) do |x|
		imp_link = tagify(ad_tag.ids[x])
		@browser.goto(imp_link)
		puts "Impression link: #{imp_link}"
		sleep 4
	end
	
	imp = get_log(@config.imp_log)
	
	puts ""
	puts "Pixel page: #{test_address[index]}"
	puts "Pixel log, prior to impression or success. #{campaign.name.capitalize} campaign:"
	pix_log = filtrate(pixel, pixel_cutoff)
	puts pix_log
	pix_log.delete_if  { | lines | lines.to_s.include?("pixel") == false }
	pixel_hash = split_log(pix_log[-1].chomp, "pixel")
	parse_pixel(pixel_hash, site.id, campaign.id, campaign.name, ad_tag.associated_account)
	
	puts ""
	puts "Served #{ad_tag.ids.length} impressions:"
	imp_array = filtrate(imp, imp_cutoff)
	puts imp_array
	last_line = imp_array[-1].split("\t")
	code = return_code(last_line[15])
	puts "Ad Tag CPM: #{ad_tag.cpm}\tReturn code: #{last_line[15]} - #{code}"
	
	puts "_____________________________________"
# We're done!
end 

