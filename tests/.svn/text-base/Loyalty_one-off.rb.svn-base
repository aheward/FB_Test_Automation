#!/usr/bin/env ruby
# Modify these variables to select
# the site and campaign you want to test...

# Obviously the names must match EXACTLY...

test_site = "EnviroInks"
campaign_name = "landing"

# If you need to test a special pixel page, define it here.
# This URL will be used instead of the default URL.
# If you aren't going to specify a URL, make sure this line reads: pixel_page = ""
pixel_page = ""

# =========================
# Do not modify anything below
# unless you know what you're doing...
require '../config/conversion_env'

loyalty_sites_SQL =<<doof
SELECT siteId, name, url, cpa, cpe, cpm, cpc, revenueShare, abTestPerc
	FROM site_data 
	WHERE name = "#{test_site}"
doof
$sites_db.results_as_hash = true
test_sites = $sites_db.execute(loyalty_sites_SQL)

#puts test_sites

# The following iterator grooms the test data...
test_sites.each do | site |
	
	campaigns_SQL =<<goof
	SELECT name, campaignId
	FROM campaign_data
	WHERE siteId = "#{site['siteId']}"
	AND name = "#{campaign_name}";
goof

	campaigns = $sites_db.execute(campaigns_SQL)
	
	site[:campaign_name] = campaigns[0]["name"]

	site[:campaign_id] = campaigns[0]["campaignId"]
	
	site[:loyalty_id] = $sites_db.execute(%|SELECT campaignId FROM campaign_data WHERE siteId = "#{site["siteId"]}" AND name = "loyalty.campaign"|)[0][0]
	
	$sites_db.results_as_hash = false
	active_ad_tags = $sites_db.execute(%|SELECT networkAdTagId FROM network_adtag_data WHERE campaignId = "#{site[:campaign_id]}";|)
	active_ad_tags.flatten!
	
	if active_ad_tags == []
		puts "Your test site has no active ad tags!"
		site[:account_id] = 0
		next
	end
	
	active_ad_tags.shuffle!
	site[:ad_tags] = active_ad_tags
	
	creatives_SQL = <<goof
	SELECT creativeId
	FROM creative_data
	WHERE siteId = "#{site["siteId"]}" AND campaignId = "#{site[:campaign_id]}"
	;
goof
	$sites_db.results_as_hash = false
	creatives = $sites_db.execute(creatives_SQL)
	creatives.flatten!
	
	site[:creatives] = creatives
	
	if site[:creatives] == []
		$sites_db.results_as_hash = true
		site[:account_id] = 0
		next
	end
	
	# It will probably be a good idea to, at some point,
	# move this conditional to its own method in the fb-methods file...
	site[:url] = case(site["siteId"].to_i)
	when 1631 then "https://online3.jimmyjohns.com/jimmy/web/?&oos=1&landed=yes"
	when 1821 then "http://pixel.fetchback.com/serve/fb/pdj?cat=&name=landing&sid=1821"
	else
		site["url"]
	end
	
	#puts site[:url]
	
	if pixel_page != ""
		
		site[:url] = pixel_page
		
	elsif site[:campaign_name] =~ /dynamic/i
		
		product_URL = $sites_db.execute(%|SELECT url FROM product_links WHERE siteId = '#{site["siteId"]}';|)
		#p product_URL
		unless product_URL == []
			site[:url] = product_URL[0][0]
		end
		
	elsif site[:campaign_name] != "landing"

		keywords = $sites_db.execute(%|SELECT keyword FROM keywords WHERE campaignId = "#{site[:campaign_id]}" AND checksum = "";|)
		full = $sites_db.execute(%|SELECT DISTINCT full_keyword FROM keywords WHERE campaignId = "#{site[:campaign_id]}" AND full_keyword IS NOT NULL;|)
		keywords << full
		begin
			keywords.flatten!.shuffle!
			#p keywords
		rescue NoMethodError
			keywords = [site[:campaign_name]]
		end
		site[:url] = site["url"] + "?fb_key=#{keywords[0]}"

	end
	
	cpm_sql = <<doof
SELECT cpm
FROM network_adtag_data
WHERE networkAdTagId = "#{site[:ad_tags][0]}"
;
doof
	site[:ad_tag_cpm] = ($sites_db.execute(cpm_sql))[0][0]
	
	# Loyalty campaign ID
	site[:loyalty_id] = $sites_db.execute(%|SELECT campaignID FROM campaign_data WHERE siteId = "#{site['siteId']}" AND name = "loyalty.campaign";|)[0][0]	
	
	# Advertiser ID
	site[:account_id] = $sites_db.execute(%|SELECT advertiserId FROM site_data WHERE siteId = "#{site['siteId']}";|)[0][0]
	
	$sites_db.results_as_hash = true
	
end

test_sites.delete_if { | site | site[:account_id] == 0 }

$browser = @config.browser

test_sites.shuffle!

conversion_type = [ 
"dtc",
"otc",
"vtc", 
"ctc"
]

# This iterator is the one that goes through the test steps...
test_sites.each do | site |

	$browser.goto("https://rptdev.fetchback.com/hub/xfb/testing/cookie_edit.php")
	
	#set the UID to not be in the control group, if there is one...
	$browser.text_field(:id, "uid").set(%|#{"%02d" %(site['abTestPerc'].to_i)}|)
	$browser.button(:id, "control").click

	puts ""
	puts ""
	puts "Testing #{site['name']} Loyalty campaign"
	puts "--------------------------------------------------"
	puts "Site ID: #{site['siteId']}"
	puts "Non-Loyalty campaign: #{site[:campaign_name]}"

	conversion = conversion_type[rand(conversion_type.length)]
		
	if site['cpc'].to_f > 0 
		puts "Site CPC: #{site['cpc']}"
	end
	if site['cpm'].to_f > 0
		puts "Site CPM: #{site['cpm']}"
	end
	if site['cpa'].to_f > 0
		puts "Site CPA: #{site['cpa']}"
	end	
	if site['revenueShare'].to_f > 0
		puts "Site revshare: #{site['revenueShare']}"
	end
		
	puts "Ad Tag IDS: #{site[:ad_tags]}"
	puts "Creative IDS: #{site[:creatives]}"
	puts "Conversion type tested: #{conversion.upcase}"
	
	# ==================
	# Actual tests all go below...
	# ==================

	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff = calc_offset_time(@config.offset, 0)
	$browser.goto(site[:url])  
	puts "Pixel page: #{site[:url]}"
	if $browser.html =~ /pixel.fetchback.com/i
		
		sleep(3) # now we have been pixeled!
		
	else
		# We need to force the pixel
		puts "Couldn't confirm pixel is there."
		puts "Forcing the pixel for this site..."
		
		key = "&fb_key="
		
		if site[:campaign_name] != "landing" && site[:campaign_name] != "dynamic"
		
			keywords = $sites_db.execute(%|SELECT keyword FROM keywords WHERE campaignId = "#{site[:campaign_id]}";|).flatten!
			begin
				keywords.shuffle!
			rescue NoMethodError
				keywords = [site[:campaign_name]]
			end
			key = "&fb_key=#{keywords[0]}"
			
		end
		
		$browser.goto("http://pixel.fetchback.com/serve/fb/pdj?cat=&name=landing&sid=#{site['siteId']}#{key}")
		sleep(1) # Now we have definitely been pixeled
	
	end	
	
	# Get contents of pixel log...
	raw_pixel_log = get_log(@config.pixel_log)
	filtered_pixel_log = filtrate(raw_pixel_log, pixel_cutoff)
	needed_pixel_event = filtered_pixel_log.find { | line | line =~ /#{site[:campaign_name]}/i }
	begin
		pixel_hash = split_log(needed_pixel_event.chomp, "pixel")
	rescue NoMethodError
		puts ""
		puts "Hmmm... "
		puts "\tIf this was a test of a keyword campaign"
		puts "\tthen you're seeing this message because"
		puts "\tthe desired campaign pixel didn't fire"
		puts "\t(though, presumably, you've been pixeled"
		puts "\tfor the landing campaign)."
		puts "\tIt's probably because the keyword link is"
		puts "\tbeing faked."
		puts ""
		puts "\tThe most common cause is that the site"
		puts "\tis doing an auto-redirect (since the URL" 
		puts "\tisn't real), so the fake URL is immediately"
		puts "\tchanged, and thus Fetchback never"
		puts "\t'sees' the keyword in the address."
		puts ""
		puts "\tOn the other hand, there's a small chance"
		puts "\t(very small) that there could be a"
		puts "\tproblem with the keyword code itself."
		puts "\tShould do some focused testing around this"
		puts "\tsite and the selected keyword (See the end"
		puts "\tof the pixel link used...)"
		puts "\t#{site[:url]}"
		puts ""
		puts "\tMoving on to the next test Site..."
		
		next
	end
	
	unless conversion == "dtc" || conversion == "otc"
		imp_link = tagify(site[:ad_tags][0])
		imp_cutoff = calc_offset_time(@config.offset, 2)
		$browser.goto(imp_link)
		#p $browser.html
		puts "Impression link: #{imp_link}"
		sleep 3
	end
	
	if conversion == "ctc" # If we're going for a CTC...
		# then "click" 
		click = clicktrack($browser, site[:url])
		puts "Click link: #{click}"
		$browser.goto(click)
	end

	# If CTC or VTC, get impression log data...
	unless conversion == "dtc" || conversion == "otc"

		raw_imp_log = get_log(@config.imp_log)
		filtered_imp_log = filtrate(raw_imp_log, imp_cutoff)
		imp_lines = filtered_imp_log.find { | line | line =~ /\timp\t/ }
		imp_hash = split_log(imp_lines.chomp, "impression")
		
	end
	
	if conversion == "otc"
		
		$browser.goto("https://rptdev.fetchback.com/hub/xfb/testing/cookie_edit.php")
		$browser.text_field(:id, "siteId").value=site['siteId']
		$browser.text_field(:id, "campaignId").value=site[:campaign_id]
		$browser.text_field(:id, "offset").set("#{7200+rand(2000000)}")
		$browser.button(:id, "otc").click
		
	end	

	success_cutoff = calc_offset_time(@config.offset, 2)
	success_link = %|https://pixel.fetchback.com/serve/fb/pdj?cat=&name=success&sid=#{site['siteId']}|
	$browser.goto(success_link)
	sleep(2)
	puts "Success link: #{success_link}"
	
	success_pixel = get_log(@confg.pixel_log)

	# Collect info from Conversion log...
	conversion_cutoff = success_cutoff
	conversion_log = get_log(@config.conversion_log)

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
	
end 
# We're done!
