#!/usr/bin/env ruby
# Modify these variables to select the site and non-loyalty
# campaign you want to test with Loyalty.
# WARNING: This should go without saying, but this script will
# fail if you pick a test site that does not have an active
# Loyalty campaign.

# Obviously the names must match EXACTLY...
test_site = "EnviroInks"
campaign_name = "landing"

# If you need to test a special pixel page, define it here.
# This URL will be used instead of the default URL.
# If you aren't going to specify a URL, make sure this line reads: PIXEL_PAGE = ""
PIXEL_PAGE = ""

# =========================
# Do not modify anything below
# unless you know what you're doing...
TEST_TYPE = :rt
require '../config/conversion_env'

test_site = data_for_a_campaign(campaign_name, test_site)
set_up_one_site(test_site[0])
test_site[0][:loyalty_id] = cpid_from_sid_and_cpname(test_site[0]['siteId'], "loyalty.campaign")

regression_conversion_test(test_site, [conversion_type])

exit


# This iterator is the one that goes through the test steps...
test_sites.each do | site |


	# Start of tests for loyalty success...
	# Go back to an impression...
	loyalty_cutoff = calc_offset_time(@config.offset, 1)
	loyalty_impression = tagify(site[:ad_tags][0])
	$browser.goto(loyalty_impression)
	puts "Loyalty impression link: #{loyalty_impression}"
	sleep 2
	
	# Loyalty campaign impression log...
	raw_loyalty_log = get_log(@config.imp_log)
	filtered_loyalty_log = filtrate(raw_loyalty_log, loyalty_cutoff)
	loyalty_imp_event = filtered_loyalty_log.find { | line | line =~ /\timp\t/ }
	loyalty_imp_hash = split_log(loyalty_imp_event.chomp, "impression")
	
	loyalty_success_cutoff = calc_offset_time(@config.offset, 1)
	$browser.goto(success_link)
	sleep(2)
	
	raw_loyalty_success_pixel_log = get_log(@config.pixel_log)
	filtered_loyalty_success_pixel_log = filtrate(raw_loyalty_success_pixel_log, loyalty_success_cutoff)
	loyalty_success_pixel_hash = split_log(filtered_loyalty_success_pixel_log[-1].chomp, "pixel")
	
	raw_loyalty_conversion_log = get_log(@config.conversion_log)
	filtered_loyalty_conversion_log = filtrate(raw_loyalty_conversion_log, loyalty_success_cutoff)
	loyalty_conversion_hash = split_log(filtered_loyalty_conversion_log[-1].chomp, "conversion")

	#Report Results...
	puts ""
	puts "Pixel log, prior to impression or success. Loyalty campaign:"
	puts filtered_pixel_log
	parse_pixel(pixel_hash, site['siteId'], site[:campaign_id], site[:campaign_name], site[:account_id])
	
	unless conversion == "dtc" || conversion == "otc"
		puts ""
		puts "Served a random impression for the client:"
		puts filtered_imp_log
		parse_impression(imp_hash, site[:campaign_id], site[:ad_tags], site[:ad_tag_cpm], site['cpc'], $sites_db)
	end

	success_array = filtrate(success_pixel, success_cutoff)
	last_line = split_log_old(success_array[-1])
	puts ""
	puts "Success pixel:"
	success_array.delete_if  { | lines | lines.to_s.include?("success") == false }
	puts success_array
	
	puts ""
	puts "#{conversion.upcase} conversion:"
	puts (filtrate(conversion_log, conversion_cutoff))[-1]
	
	puts ""	
	puts "Loyalty impression:"
	puts filtered_loyalty_log
	parse_impression(loyalty_imp_hash, site[:loyalty_id], site[:ad_tags], site[:ad_tag_cpm], site['cpc'], $sites_db)
	
	puts ""
	puts "Loyalty sucess pixel:"
	puts filtered_loyalty_success_pixel_log
	parse_pixel(loyalty_success_pixel_hash, site['siteId'],  site[:loyalty_id], "loyalty.campaign", site[:account_id])
	
	puts ""
	puts "Conversion log for Loyalty:"
	puts filtered_loyalty_conversion_log
	parse_conversion(loyalty_conversion_hash, conversion, loyalty_success_pixel_hash, loyalty_imp_hash, site[:loyalty_id], site['siteId'])
	
	puts "_____________________________________"

