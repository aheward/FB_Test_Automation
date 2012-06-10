#!/usr/bin/env ruby
require '../config/env.rb'
require '../lib/pixel_imp_conversions'

include LogManipulators
include Randomizers

@config = FBConfig.new(:rt)
$sites_db = @config.sites_db

test_sites = []

x_sites = $sites_db.execute(%|SELECT siteId FROM site_data WHERE siteId IN (SELECT siteId FROM campaign_data WHERE disableDirectPdc = '1' and siteId IN (SELECT siteId FROM creative_data));|)

x_sites.flatten!

exclude_these_sites = [ 3341, 1161 ]

test_sites = x_sites - exclude_these_sites

test_sites.shuffle!

sql =<<doof
SELECT s.name site_name, s.siteId, s.url, c.name campaign_name, c.campaignId,
	s.cpm, s.cpa, s.revenueShare, s.cpc, s.cpe, s.advertiserId, s.abTestPerc
FROM site_data s, campaign_data c
WHERE c.siteId = s.siteId
	AND c.campaignId 
		IN (SELECT campaignId FROM creative_data)
	AND s.siteId
		IN (#{test_sites.join(", ")})
;
doof

$sites_db.results_as_hash = true
sites_hashes = $sites_db.execute(sql)

sites_hashes.shuffle!
#puts sites_hashes

site_ids = Array.new

$sites_db.results_as_hash = false
puts "*****************************"
puts "CTC, and VTC tests for Floodlight Sites"
puts "*****************************"

conversion_type = [ 
"vtc", 
"ctc"
]

sites_hashes.each do | hash |
	
	next if site_ids.include?(hash["siteId"])
	next if hash["siteId"].to_i == 276 && hash["campaign_name"] != "General Campaign"# Most BOMGAR campaigns will not test right.
	next if hash["campaign_name"] == "control"
	next if hash["campaign_name"] == "loyalty.campaign"

	puts ""
	puts "============================="
	puts "Testing #{hash["site_name"]}"
	puts "============================="
	puts "Site ID: #{hash["siteId"]}"
	
	hash[:url] = get_link(hash["campaign_name"], hash["siteId"], hash["campaignId"], hash["url"], hash["revenueShare"])
		
	puts "Campaign: #{hash['campaign_name']}, ID: #{hash['campaignId']}"
	
	#Prepare links for affiliate program...
	
	code = FetchBack.encode_affiliate_param(hash["siteId"], 'PPJ1')
	
	pepperjam_URL_1 = "http://pixel.fetchback.com/serve/fb/afl?afc=PPJ1&afx=#{code}&afu="
	pepperjam_URL_2 = "http://pixel.fetchback.com/serve/fb/afl;afc=PPJ1,afx=#{code},afu="
	
	# Pick which one to use...
	z = rand(2)
	if z == 0
		affiliate_link = pepperjam_URL_1 + CGI::escape(hash[:url])
	else
		affiliate_link = pepperjam_URL_2 + CGI::escape(CGI::escape(hash[:url]))
	end

	if hash["cpc"].to_f > 0 
		puts "Site CPC: #{hash["cpc"]}"
	end
	if hash["cpm"].to_f > 0
		puts "Site CPM: #{hash["cpm"]}"
	end
	if hash["cpa"].to_f > 0
		puts "Site CPA: #{hash["cpa"]}"
	end
	if hash["cpe"].to_f > 0
		puts "Site CPE: #{hash["cpe"]}"
	end
	if hash["revenueShare"].to_f > 0
		puts "Site revshare: #{hash["revenueShare"]}"
	end

	#get ad tag
	active_ad_tags = $sites_db.execute(%|SELECT networkAdTagId FROM network_adtag_data WHERE campaignId = "#{hash['campaignId']}";|)
	begin		
		active_ad_tags.flatten!.shuffle!
	rescue NoMethodError
		puts "Apparently there are no active Ad Tags?"
		puts "I assume this is a problem of bad data"
		puts "in the test db."
		puts ""
		puts "Skipping this test Site/Campaign..."
		puts ""
		next
	end
	
	test_tag = active_ad_tags[0]

cpm_sql = <<doof
SELECT cpm, name, primaryId
FROM network_adtag_data
WHERE networkAdTagId = "#{test_tag}"
;
doof
	
	result = ($sites_db.execute(cpm_sql))[0]
	
	begin
		ad_tag_cpm = result[0]
	rescue NoMethodError # If the result of the above query is Null...
		site_ids << hash["siteId"]
		puts "Skipping this test because of missing data"
		next
	end
	
	network_name = result[1]
	network_id = result[2]
		
	creative = tagify(test_tag)
	
creative_ids_sql =<<goof
SELECT creativeId
FROM creative_data
WHERE campaignId = "#{hash['campaignId']}"
;
goof

	creative_ids = $sites_db.execute(creative_ids_sql).flatten!

	puts ""
	puts "Network: #{network_name}  ID: #{network_id}"
	puts "Count of active ad tags: #{active_ad_tags.length}"

	puts "Ad Tag IDS: #{active_ad_tags}"
	puts "Creative IDS: #{creative_ids}"
	
	# ==================
	# Actual tests all go below...
	# ==================

	# Conversions iterator...
	0.upto(conversion_type.length - 1) do | conversion_index |
		
		$browser = @config.browser
		
		$browser.goto("https://rptdev.fetchback.com/hub/xfb/testing/cookie_edit.php")
		
		$browser.text_field(:id, "uid").set(%|#{"%02d" %(hash['abTestPerc'].to_i)}|)
		$browser.button(:id, "control").click
		

		
		# Go to the page so as to get pixeled by the desired campaign...
		x = rand(2)
		if x == 0 && code != -1 && ( hash['campaign_name'] == "landing" || hash['campaign_name'] == "dynamic" )
			pixel_link = affiliate_link
		else
			pixel_link = hash[:url]
			x = 3 # This line is needed to make sure we don't go to affiliate logs later.
		end
		
		pixel_cutoff = calc_offset_time(@config.offset, 2)
		#puts pixel_cutoff
		$browser.goto(pixel_link)
		
		if $browser.html =~ /pixel.fetchback.com/i
			
			sleep(3) # now we have been pixeled!
			
		else
			# We need to force the pixel
			
			key = "&fb_key="
			
			if hash["campaign_name"] == "landing" || hash["campaign_name"] == "dynamic"
				keywords = ["not a keyword campaign"]
			else	
			
				keywords = $sites_db.execute(%|SELECT keyword FROM keywords WHERE campaignId = "#{hash["campaignId"]}";|).flatten!
				begin
					keywords.shuffle!
				rescue NoMethodError
					keywords = [hash["campaign_name"]]
				end
				key = "&fb_key=#{keywords[0]}"
			end
			
			$browser.goto("http://pixel.fetchback.com/serve/fb/pdj?cat=&name=landing&sid=#{hash['siteId']}#{key}")
			sleep(1) # Now we have definitely been pixeled
			
		end	
		
		puts ""
		puts "#{conversion_type[conversion_index].upcase} TEST"
		puts "-----------------------------------------"
		
		# Get contents of pixel log...
		pixel = get_log(@config.pixel_log)
		#puts pixel
		
		if x == 0  # Meaning we want to test an affiliate link

			affiliate = get_log(@config.affiliate_log)
			affiliate = affiliate_filtrate(affiliate, pixel_cutoff)
			affiliate_hash = split_log(affiliate[:redirect][0], "affiliate_redirect")
			puts ""
			puts "Affiliate Redirect Entry:"
			puts affiliate[:redirect]
			parse_affiliate(affiliate_hash, conversion_type[conversion_index], hash['siteId'], hash['campaignId'])
			
		end	
		
		# If it's a VTC or CTC, then serve an impression...
		imp_cutoff = calc_offset_time(@config.offset, 3)
		$browser.goto(creative)
		puts "Impression link: #{creative}"
		sleep 4
		if $browser.html =~ /src=.http...pixel.fetchback.com.serve.fb.pd..uatFilter=true&amp;cat=&amp;name=.+&amp;sid=#{hash['siteId']}/
			puts "Fetchback pixel found in ad"
		else
			puts "---No pixel stuffing found!"
			puts $browser.html
			puts "iframe.src=.http...pixel.fetchback.com.serve.fb.pd..uatFilter=true&cat=&name=landing&sid=#{hash['siteId']}"
		end
			
		if conversion_type[conversion_index] == "ctc" # If we're going for a CTC...
			# then "click" ...
			click = clicktrack($browser, hash[:url])
			puts "Clicktracking link: #{click}"
			$browser.goto(click)
		end
		
		# If CTC or VTC, get impression log data...
		imp_hash = {}
		unless conversion_type[conversion_index] == "dtc" || conversion_type[conversion_index] == "otc" 
			
			imp = get_log(@config.imp_log)
			imp_array = filtrate(imp, imp_cutoff)
			imp_lines = imp_array.find { | line | line =~ /\timp\t/ }
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

		# Success
		conversion_cutoff = success_cutoff = calc_offset_time(@config.offset, 3)
		unless rand(15) == 0
			crv = "#{rand(500)}"+".#{rand(10)}"+"#{rand(10)}"
		else
			crv = (rand(100) + 1).to_s
		end	
		oid = random_nicelink(16)
		success_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=#{random_nicelink}&name=success&sid=#{hash["siteId"]}"  + "&crv=#{crv}" + "&oid=#{oid}"
		$browser.goto(success_link)
		sleep(2)

		success_pixel = get_log(@config.pixel_log)

		# Collect info from Conversion log...
		conversion_log = get_log(@config.conversion_log)

		if x == 0 # Meaning we are using the affiliate link for testing...
			afl_conv_log = get_log(@config.affiliate_log)
		end
		
		if hash['campaign_name'] == "dynamic"
			product_cutoff = pixel_cutoff 
			product_log = get_log(@config.product_log)
			
			array = []
			product_log.each_line do | line |
				if line =~ /\t#{hash['siteId']}/
					array << line
				end	
			end
			array.delete_if  { | lines | ((lines.to_s)[16..24] < product_cutoff ) == true }
			product_log = array
			# The below is code for the future...
			# There is currently no parsing code for the product log.
=begin			
			begin
				product_hash = split_log(product_log[0].chomp, "products")
			rescue NoMethodError
				
			end
=end			
		end
		
		#Report Results....
		
		puts "Pixel page: #{pixel_link}"
		puts "Pixel log, prior to impression or success. #{hash['campaign_name'].capitalize} campaign:"
		pixel = filtrate(pixel, pixel_cutoff)

		puts pixel

		pixel = pixel.find { | line | line =~ /#{hash['campaign_name']}/i }
		begin
			pixel_hash = split_log(pixel.chomp, "pixel")
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
			puts "\tsite and the selected keyword - #{hash[:url]}" 
			puts ""
			puts "\tMoving on to the next test Site..."
			#site_ids << hash["siteId"] - I have this commented out because we could test another campaign from the same site.
			$browser.close
			break
		end
		parse_pixel(pixel_hash, hash['siteId'], hash['campaignId'], hash['campaign_name'], hash['advertiserId'], test_tag)
		
		click_hash = {}
		
		unless conversion_type[conversion_index] == "dtc" ||  conversion_type[conversion_index] == "otc"
			puts ""
			puts "Served impression:"
			puts imp_array
			#p imp_lines
			hover_line = imp_array.find { | line | line =~ /\thover\t/ }
			#p hover_line
			
			parse_impression(imp_hash, hash['campaignId'], active_ad_tags, ad_tag_cpm, hash['cpc'])
			
			if conversion_type[conversion_index] == "ctc"
				click_line = imp_array.find { | line | line =~ /\tclick\t/ }
				
				if click_line != nil
					click_hash = split_log(click_line.chomp, "impression")
					parse_impression(click_hash, hash['campaignId'], active_ad_tags, ad_tag_cpm, hash['cpc'])
				end
			end
			
			if hover_line != nil
				hover_hash = split_log(hover_line.chomp, "impression")
				parse_impression(hover_hash, hash['campaignId'], active_ad_tags, ad_tag_cpm, hash['cpc'])
				#p hover_hash
			end	
			
			#p imp_hash

		end

		success_array = filtrate(success_pixel, success_cutoff)
		#puts success_cutoff
		#puts success_array
		success_array.delete_if  { | lines | lines.to_s.include?("success") == false }
		#puts success_array
		begin
			success_pixel_hash = split_log(success_array[-1].chomp, "pixel")
		rescue NoMethodError
			puts "I can't find the event I'm looking for in the log."
			puts ""
			puts "Skipping this test."
			puts ""
			puts "You should make sure there's not a clock problem."
			puts "Success cutoff time: #{success_cutoff}"
			puts ""
			$browser.close
			break
		end
		puts ""
		puts "Success pixel..."
		puts "Success link: #{success_link}"
		puts "CRV\t\t\t\t\tOID"
		puts "Expected:\t#{crv}\t\tExpected:\t#{oid}"
	
		puts success_array
		parse_pixel(success_pixel_hash, hash['siteId'], hash['campaignId'], hash['campaign_name'], hash['advertiserId'], test_tag)
		
		puts ""
		puts "#{conversion_type[conversion_index].upcase} conversion:"
		conv = (filtrate(conversion_log, conversion_cutoff))[-1]
		puts conv
		conversion_hash = split_log(conv.chomp, "conversion")

		parse_conversion(conversion_hash, conversion_type[conversion_index], success_pixel_hash, imp_hash, hash['campaignId'], hash['siteId'])

		if x == 0
			puts ""
			puts "Affiliate Conversion Entry:"
			afl_conv_log = affiliate_filtrate(afl_conv_log, pixel_cutoff)
			puts afl_conv_log[:conversion]
			afl_conv_hash = split_log(afl_conv_log[:conversion][-1], "affiliate_conversion")
			parse_affiliate(afl_conv_hash, conversion_type[conversion_index],  hash['siteId'], hash['campaignId'])
		end
		
		if hash["campaign_name"] =~ /dynamic/i
			puts ""
			puts "Product log:"
			prod = product_filtrate(product_log, pixel_cutoff)
			puts prod
			product_hash = split_log(prod[-1], "products")
			#puts "product hash:"
			#p product_hash
			begin
				parse_product(product_hash, hash["siteId"])
			rescue NoMethodError
				puts "---There's a problem with the product log. Please investigate."
			end
			puts ""
		end
		puts "_____________________________________"
		
		$browser.close

	end 
	
	site_ids << hash["siteId"]

# We're done!
end 