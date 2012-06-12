#!/usr/bin/env ruby
TEST_TYPE = :rt
require '../config/conversion_env'

test_sites = get_merit_test_data(10)
test_sites.each { |s|
  p s['site_name']
  p s['campaign_name']
  p s[:url]
}
exit
=begin
visit CookieEditor do |p|
  p.set_control_cookie("99")
end

offset_count = 0

sites_hashes.each do | hash |
	
	next if tested_sites.include?(hash["siteId"])

	error = site_merit_values(hash)
	if error == "Error"
		puts "--Missing merit values for this site."
		puts "--moving on to next test..."
		next
	end

	puts ""
	puts "Testing #{hash["site_name"]}, #{hash["campaign_name"]} campaign."
	puts "--------------------------------------------------"
	puts "Site ID: #{hash["siteId"]}"
	puts "Campaign ID: #{hash["campaignId"]}"
	puts "Conversion window: #{hash["conversionWindow"]} days"
	
	hash[:url] = get_link(hash)
	
	pixel_cutoff = calc_offset_time(@config.offset, 0)
	@browser.goto(hash[:url])
	puts "Pixel page: #{hash[:url]}"
	sleep(1)
  tested_sites << hash["siteId"]
	
	pixel = get_log(@config.pixel_log)
	
	#get ad tag
	active_ad_tags = ad_tags_for_campaign(hash["campaignId"])
	active_ad_tags.flatten!
	
	test_tag = active_ad_tags[rand(active_ad_tags.length)]

cpm_sql = <<doof
SELECT cpm
FROM network_adtag_data
WHERE networkAdTagId = "#{test_tag}"
;
doof
	begin
		ad_tag_cpm = ($sites_db.execute(cpm_sql))[0][0]
	rescue NoMethodError
		puts "Can't find the CPM value for the selected Ad Tag."
		puts "That's just wacky. Probably means it's time to"
		puts "update the sites.db file."
		puts "In any case, we're moving on to the next test site..."
		x += 1
		next
	end

	creative = tagify(test_tag)
	imp_cutoff = calc_offset_time(@config.offset, 1)
	browser.goto(creative)
	puts "Impression link: #{creative}"
	sleep(2.5)

	imp = get_log(@config.imp_log)
	imp_log = filtrate(imp, imp_cutoff)
	imp_hash = split_log(imp_log[-1].chomp, "impression")

  visit CookieEditor do |p|
	p.set_merit_offset(imp_hash[:adtag_id], imp_hash[:creative_id]
	cookie_edit.offset=MERIT_OFFSETS[offset_count]
	cookie_edit.merit
	
	# Success

	unless rand(15) == 0
		crv = "#{rand(500)}"+".#{rand(10)}"+"#{rand(10)}"
	else
		crv = (rand(100) + 1).to_s
	end	
	oid = random_alphanums_plus(16)
	success_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=#{random_nicelink}&name=success&sid=#{hash["siteId"]}"  + "&crv=#{crv}" + "&oid=#{oid}"
	
	success_cutoff = calc_offset_time(@config.offset, 1)
	browser.goto(success_link)
	sleep(2.5)
	puts "Success link: #{success_link}"
	
	success_pixel = get_log(@config.pixel_log)
	
	conversion_log = get_log(@config.conversion_log)

	# Report results
	
	puts ""
	puts "Pixel log, prior to impression or success. #{hash["campaign_name"].capitalize} campaign:"
	puts filtrate(pixel, pixel_cutoff)

	puts ""
	puts "Served impression:"
	puts imp_log
	parse_impression(imp_hash, hash["campaignId"], active_ad_tags, ad_tag_cpm, hash["cpc"])

	puts ""
	puts "Success pixel:"
	success_array = filtrate(success_pixel, success_cutoff)
	success_array.delete_if  { | lines | lines.to_s.include?("success") == false }
	begin
		success_pixel_hash = split_log(success_array[-1].chomp, "pixel")
	rescue NoMethodError
		puts "--Missing log entry for success for some reason."
		puts "--Skipping to next test, now..."
		next
	end
	puts success_array
	parse_pixel(success_pixel_hash, hash["siteId"].to_s, hash["campaignId"].to_s, hash["campaign_name"], hash["advertiserId"], test_tag)
	
	puts ""
	puts "Conversion Log:"
	puts filtrate(conversion_log, success_cutoff)
	conversion_hash = split_log(filtrate(conversion_log, success_cutoff)[-1].chomp, "conversion")
	parse_conversion(conversion_hash, "vtc", success_pixel_hash, imp_hash, hash["campaignId"].to_s, hash["siteId"].to_s, merit30, merit7, merit3, merit1)

	puts "__________________________________"

  browser.show_cookies

  offset_count += 1
	
end
=end