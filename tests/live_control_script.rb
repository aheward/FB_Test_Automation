#!/usr/bin/env ruby
require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido-classes'

include LogManipulators
include Randomizers
include FidoTamers

@config = FBConfig.new(:prod)

@browser = @config.browser
@browser.goto(@config.cookie_editor)
@browser.text_field(:id, "uid").set("04")
@browser.button(:id, "control").click
	
@browser.goto(@config.data_wiki)

if @browser.button(:name, "login").exist?
  unless @browser.text_field(:id, "os_username").value.include?(@config.confluence_username)
		@browser.text_field(:id, "os_username").set(@config.confluence_username)
		@browser.text_field(:id, "os_password").focus
		@browser.text_field(:id, "os_password").set(@config.confluence_password)
	end
	@browser.button(:name, "login").click
end

test_data = @browser.table(:class => "confluenceTable", :index => 6).to_a

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
puts "Control tests"
puts "============================="
puts ""
puts "Sites checked:"
puts client_name

client_name.each_index do | index |
	
	# Open Browser to Fido...
	@browser.goto("http://#{@config.test_site}/fido/")
		
	# Log in to site...
	fido_log_in(@browser, @config.fido_username, @config.fido_password)

	# Navigate to Client Site in Fido...
	site_exist = open_fido_site(@browser, client_name[index]) 
	next if site_exist != true 

	#Get Site and Campaign Variables...

	site = Site.new(@browser)

	puts ""
	puts ""
	puts "Testing #{site.name} Control campaign"
	puts "--------------------------------------------------"
	puts "Site ID: #{site.id}"

	if site.cpc.to_f > 0 
		puts "Site CPC: #{site.cpc}"
	end
	if site.cpm.to_f > 0
		puts "Site CPM: #{site.cpm}"
	end
	if site.cpa.to_f > 0
		puts "Site CPA: #{site.cpa}"
	end	
	if site.percent_revshare.to_f > 0
		puts "Site revshare: #{site.percent_revshare}"
	end
	
	# Go to Loyalty Campaign page in Fido
	@browser.link(:text, "control").click
	control = Campaign.new(@browser)

	if control.cpc.to_f > 0 
		puts "Control CPC: #{control.cpc}"
	end
	if control.cpm.to_f > 0
		puts "Control CPM: #{control.cpm}"
	end
	if control.cpa.to_f > 0
		puts "Control CPA: #{control.cpa}"
	end	
	if control.percent_revshare.to_f > 0
		puts "Control revshare: #{control.percent_revshare}"
	end
	if control.flat_fee_value.to_f > 0
		puts "Control flat fee value:  #{control.flat_fee_value}"
	end

	@browser.link(:text, "Site Home").click 
	@browser.link(:text, campaign_name[index]).click 
	campaign = Campaign.new(@browser)
	puts "Campaign ID: #{campaign.id}"

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

	puts "Ad Tag IDS: #{ad_tag.ids}"
	puts "Creative IDS (non-control): #{campaign.active_creative_ids}"
	
	# ==================
	# Actual tests all go below...
	# ==================
		
	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff = calc_offset_time(@config.offset, 9)
	@browser.goto(test_address[index])  
	puts "Pixel page: #{test_address[index]}"
	sleep(1)	# now we have been pixeled!

	# Get contents of pixel log...

	pixel = get_log(@config.pixel_log)
	
	imp_link = tagify(ad_tag.ids[rand(ad_tag.ids.length - 1)])
	imp_cutoff = calc_offset_time(@config.offset, 10)
	@browser.goto(imp_link)
	puts "Impression link: #{imp_link}"
	sleep 3
	
	imp = get_log(@config.imp_log)
	
	#Report results
	puts ""
	puts "Pixel log, prior to impression or success. #{campaign.name.capitalize} campaign:"
	puts filtrate(pixel, pixel_cutoff)

	puts ""
	puts "Served impression:"
	imp_line = filtrate(imp, imp_cutoff)
	puts imp_line
	imp_hash = split_log(imp_line[-1], "impression")
	parse_impression(imp_hash, control.id, ad_tag.ids, ad_tag.cpm, control.cpc, @config.sites_db)
# We're done!
end 