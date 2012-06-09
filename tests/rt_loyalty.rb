#!/usr/bin/env ruby
=begin

Tests the Loyalty Campaign

Things to do:
- Fix the loyalty success to use CTC, VTC, and DTC conversions.
- Refactor with RSpec and Test/Unit when there's time.

=end
require '../config/conversion_env'

x_sites = $sites_db.get_site_ids_for_loyalty_camps
x_sites.flatten!.sort!

exclude_these_sites = BlacklistedSites.new.sites

loyalty_sites = x_sites - exclude_these_sites

test_sites = $sites_db.get_loyalty_site_date(loyalty_sites)

# The following iterator grooms the test data...
test_sites.each do | site |

	campaigns = $sites_db.get_non_landing_campaign_data(site['siteId'])
	campaigns.delete_if { |camp| camp["campaign_name"] == "success"}
	campaigns.delete_if { |camp| camp["campaign_name"] == "control"}
	campaigns.delete_if { |camp| camp["campaign_name"] =~ /opt.*out/i}
	campaigns.delete_if { |camp| camp["campaign_name"] == "loyalty.campaign"}
	
	campaigns.shuffle!
	
	begin
		site[:campaign_name] = campaigns[0]["campaign_name"]
	rescue NoMethodError
		site[:account_id] = 0
		next
	end
	
	site[:campaign_id] = campaigns[0]["campaignId"]
	
	site[:loyalty_id] = $sites_db.get_cpid_from_sid_and_cpname(site["siteId"], "loyalty.campaign")

  site[:ad_tags] = $sites_db.get_ad_tags_for_campaign(campaigns[0]['campaignId'])
  site[:ad_tags].flatten!
	
	if site[:ad_tags] == []
		site[:account_id] = 0
		next
	end

  site[:ad_tags].shuffle!

	creatives = $sites_db.get_creatives_by_site_and_camp(site["siteId"], campaigns[0]['campaignId'])
	creatives.flatten!
	
	site[:creatives] = creatives
	
	if site[:creatives] == []
		site[:account_id] = 0
		next
	end
	
	site[:url] = get_link(site[:campaign_name], site["siteId"], site[:campaign_id], site["url"], site["revenueShare"])

	site[:ad_tag_cpm] = $sites_db.get_network_cpm(site[:ad_tags][0])
	
	# Advertiser ID
	site[:account_id] = $sites_db.get_account_id_for_site(site['siteId'])
	
end

test_sites.delete_if { | site | site[:account_id] == 0 }

@browser = @config.browser

test_sites.shuffle!

conversion_type = [ 
"dtc",
"otc",
"vtc", 
"ctc"
]

# This iterator is the one that goes through the test steps...
test_sites.each do | site |

	@browser.goto(@config.cookie_editor)
	
	#set the UID to not be in the control group, if there is one...
	@browser.text_field(:id, "uid").set(%|#{"%02d" %(site['abTestPerc'].to_i)}|)
	@browser.button(:id, "control").click

	@browser.dirty(site['siteId'], 2, 3)
  conversion = conversion_type[rand(conversion_type.length)]
  conversion_report_header(site['name'], site['siteId'], "Loyalty, #{site[:campaign_name]}", site[:loyalty_id], site['cpc'], site['cpm'], site['cpa'], site['cpe'], site['revenueShare'], site['abTestPerc'], conversion)

	# ==================
	# Actual tests all go below...
	# ==================

	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff = calc_offset_time(@config.offset, 3)
  pixel_url = @browser.get_pixeled(site[:url], site[:campaign_name], site[:campaign_id], site['siteId'])

	# Get contents of pixel log...
	raw_pixel_log = get_log(@config.pixel_log)

	@browser.dirty(site['siteId'])

	unless conversion == "dtc" || conversion == "otc"
		imp_cutoff = calc_offset_time(@config.offset, 3)
		@browser.get_impified(@config.imp_seconds, @config.extra_imp_count, site[:ad_tags], conversion_type, site[:url])
	end

	# If CTC or VTC, get impression log data...
	unless conversion == "dtc" || conversion == "otc"

		raw_imp_log = get_log(@config.imp_log)
		filtered_imp_log = filtrate(raw_imp_log, imp_cutoff)
		imp_lines = filtered_imp_log.find { | line | line =~ /\timp\t/ }
		imp_hash = split_log(imp_lines.chomp, "impression")
		
	end
	
	if conversion == "otc"
		
		@browser.goto(@config.cookie_editor)
		@browser.text_field(:id, "siteId").value=site['siteId']
		@browser.text_field(:id, "campaignId").value=site[:campaign_id]
		@browser.text_field(:id, "offset").set("#{7200+rand(200000)}")
		sleep 5
		@browser.button(:id, "otc").click
		
	end	

	success_cutoff = calc_offset_time(@config.offset, 3)
	success_link = %|https://pixel.fetchback.com/serve/fb/pdj?cat=&name=success&sid=#{site['siteId']}|
	@browser.goto(success_link)
	sleep(2)
	puts "Success link: #{success_link}"
	
	success_pixel = get_log(@config.pixel_log)

	# Collect info from Conversion log...
	conversion_cutoff = success_cutoff
	conversion_log = get_log(@config.conversion_log)
	
	@browser.dirty(site['siteId'])
	sleep(4)

	# Start of tests for loyalty success...
	# Go back to an impression...
	loyalty_cutoff = calc_offset_time(@config.offset, 2)
	loyalty_impression = tagify(site[:ad_tags][0])
	@browser.goto(loyalty_impression)
	puts "Loyalty impression link: #{loyalty_impression}"
	sleep 2
	
	# Loyalty campaign impression log...
	raw_loyalty_log = get_log(@config.imp_log)
	filtered_loyalty_log = filtrate(raw_loyalty_log, loyalty_cutoff)
	loyalty_imp_event = filtered_loyalty_log.find { | line | line =~ /\timp\t/ }
	loyalty_imp_hash = split_log(loyalty_imp_event.chomp, "impression")
	
	@browser.dirty(site['siteId'])
	sleep(4)
	
	loyalty_success_cutoff = calc_offset_time(@config.offset, 2)
	@browser.goto(success_link)
	sleep(2)
	
	raw_loyalty_success_pixel_log = get_log(@config.pixel_log)
	filtered_loyalty_success_pixel_log = filtrate(raw_loyalty_success_pixel_log, loyalty_success_cutoff)
	loyalty_success_pixel_hash = split_log(filtered_loyalty_success_pixel_log[-1].chomp, "pixel")
	
	raw_loyalty_conversion_log = get_log(@config.conversion_log)
	filtered_loyalty_conversion_log = filtrate(raw_loyalty_conversion_log, loyalty_success_cutoff)
	loyalty_conversion_hash = split_log(filtered_loyalty_conversion_log[-1].chomp, "conversion")

	#Report Results...
  pixel_data = pixel_report(pixel_url, site['siteId'], site[:campaign_name], site[:campaign_id], site[:account_id], pixel_cutoff, raw_pixel_log, site[:ad_tags][0])
  if pixel_data == "bad data"
    break
  end

	unless conversion == "dtc" || conversion == "otc"
		puts ""
		puts "Served a random impression for the client:"
		puts filtered_imp_log
		parse_impression(imp_hash, site[:campaign_id], site[:ad_tags], site[:ad_tag_cpm], site['cpc'])
	end

	success_array = filtrate(success_pixel, success_cutoff)
	last_line = split_log_old(success_array[-1])
	puts ""
	puts "Success pixel:"
	success_array.delete_if { | lines | lines.to_s.include?("success") == false }
	puts success_array
	
	puts ""
	puts "#{conversion.upcase} conversion:"
	puts (filtrate(conversion_log, conversion_cutoff))[-1]
	
	puts ""	
	puts "Loyalty impression:"
	puts filtered_loyalty_log
	parse_impression(loyalty_imp_hash, site[:loyalty_id], site[:ad_tags], site[:ad_tag_cpm], site['cpc'])
	
	puts ""
	puts "Loyalty sucess pixel:"
	puts filtered_loyalty_success_pixel_log
	parse_pixel(loyalty_success_pixel_hash, site['siteId'],  site[:loyalty_id], "loyalty.campaign", site[:account_id], site[:ad_tags][0])
	
	puts ""
	puts "Conversion log for Loyalty:"
	puts filtered_loyalty_conversion_log
	parse_conversion(loyalty_conversion_hash, conversion, loyalty_success_pixel_hash, loyalty_imp_hash, site[:loyalty_id], site['siteId'])
	
	puts "_____________________________________"
	
end 
# We're done!
