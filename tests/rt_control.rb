#!/usr/bin/env ruby
=begin

Tests the Control Campaign on the test sites.

=end
TEST_TYPE = :rt
require '../config/conversion_env'

p $test_site
p $test_site_ip
p $pixel_log
p $imp_log
p $impvar_log
p $conversion_log
p $affiliate_log
p $product_log
p $proxy_log
p $pixel_log1
p $imp_log1
p $impvar_log1
p $conversion_log1
p $affiliate_log1
p $product_log1
p $proxy_log1

test_sites = get_control_test_data(10)
p test_sites
regression_conversion_test(@config, test_sites, %w{vtc})
exit
test_sites.each do | site |


	browser.goto(@config.cookie_editor)
	fb_uid = "%02d" %(site['abTestPerc'].to_i - 1) # Code to make sure there's always a leading zero for single digits.
	cookie_page = Cookies.new browser
  cookie_page.uid=fb_uid
	cookie_page.control

  conversion_report_header(site['site_name'], site['siteId'], "control", site[:control_id], site['cpc'], site['cpm'], site['cpa'], site['cpe'], site['reveueShare'], site['abTestPerc'], "vtc")

  network_ad_tags_report(site[:account_id], "", site[:ad_tags], site[:creatives])

	# ==================
	# Actual tests all go below...
	# ==================
		
	# Go to the page so as to get pixeled by the desired campaign...
	pixel_cutoff = calc_offset_time(@config.offset, 2)
	pixel_url = browser.get_pixeled(site[:url], site[:campaign_name], site['campaignId'], site['siteId'], $sites_db)

	# Get contents of pixel log...
	pixel_log = get_log(@config.pixel_log)

	imp_cutoff = calc_offset_time(@config.offset, 2)
	browser.get_impified(2.5, 0, site[:ad_tags], "vtc", site[:url])

	# Success
	success_cutoff = calc_offset_time(@config.offset, 2)

	success_data = browser.get_success(site['siteId'])

	success_pixel_log = get_log(@config.pixel_log)

	# Collect info from Conversion log...
	conversion_log = get_log(@config.conversion_log)

	#Report results
  pixel_data = pixel_report(pixel_url, site['siteId'], "control", site[:control_id], site[:account_id], pixel_cutoff, pixel_log, site[:ad_tags][0])
  if pixel_data == "bad data"
    next
  end

  imp_report_data = impression_report(@config.imp_log, imp_cutoff, site[:control_id], site[:ad_tags], site["cpm"], site["cpc"], $sites_db, "vtc")
  if imp_report_data == "bad data"
    next
  end

  success_pixel_report = success_report(success_pixel_log, success_cutoff, site['siteId'], site[:control_id], "control", site[:account_id],success_data, site[:ad_tags][0])
  if success_pixel_report == "no pixel"
    next
  end

  conversion_report("vtc", conversion_log, success_cutoff, success_pixel_report, imp_report_data, site[:control_id], site['siteId'])

  browser.show_cookies
# We're done!
end 