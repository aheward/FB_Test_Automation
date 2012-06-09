#!/usr/bin/env ruby
=begin

Tests the Control Campaign on the test sites.

=end
require '../config/conversion_env'

control_sites = $sites_db.get_sites_with_control_camps
control_sites.flatten!.sort!

test_sites = $sites_db.get_control_site_data(control_sites)

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

	active_ad_tags = $sites_db.get_ad_tags_for_campaign(campaigns[0]['campaignId'])
	active_ad_tags.flatten!
	
	if active_ad_tags == []
		site[:account_id] = 0
		next
	end
	
	active_ad_tags.shuffle!
	site[:ad_tags] = active_ad_tags

	creatives = $sites_db.get_creatives_by_site_and_camp(site["siteId"], campaigns[0]['campaignId'])
	creatives.flatten!
	
	site[:creatives] = creatives
	
	if site[:creatives] == []
		site[:account_id] = 0
		next
	end
	
	site[:url] = get_link(site[:campaign_name], site["siteId"], campaigns[0]['campaignId'], site["url"], site["revenueShare"])

	site[:ad_tag_cpm] = $sites_db.get_network_cpm(site[:ad_tags][0])
	
	# Control campaign ID
	site[:control_id] = $sites_db.get_control_camp_id(site['siteId'])
	
	# Advertiser ID
	site[:account_id] = $sites_db.get_account_id_for_site(site['siteId'])

end

blacklist = BlacklistedSites.new.sites

test_sites.delete_if { | site | site[:account_id] == 0 }
test_sites.delete_if { | site | blacklist.include?(site['siteId']) }

browser = @config.browser

test_sites.shuffle!

test_sites.each do | site |

	next if site == {}

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