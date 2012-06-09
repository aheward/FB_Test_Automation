#!/usr/bin/env ruby
# Modify these variables to select
# the site and campaign you want to test...

# Obviously the names must match EXACTLY...

test_site = "Kansas City Steaks"
campaign_name = "landing"

# If you need to test a special pixel page, define it here.
# This URL will be used instead of the default URL.
# If you aren't going to specify a URL, make sure this line reads: pixel_page = ""
pixel_page = ""

# =========================
require '../config/conversion_env'
sites_hashes = $sites_db.get_data_for_a_campaign(campaign_name, test_site)

sites_hashes.shuffle!

conversion_type = "ctc"

sites_hashes.each do | hash |

	conversion_report_header(hash['site_name'], hash['siteId'], hash['campaign_name'], hash['campaignId'], hash['cpc'], hash['cpm'], hash['cpa'], hash['cpe'], hash['revenueShare'], hash['abTestPerc'], conversion_type)
	
	hash[:url] = get_link(hash["campaign_name"], hash["siteId"], hash["campaignId"], hash["url"], hash["revenueShare"], pixel_page)

	#Create pixel link...
	link_info = affiliate_or_regular(hash['siteId'], hash[:url], hash["campaign_name"])
  pixel_link = link_info[:pixel]
  aff = link_info[:x]

  #get ad tag
  active_ad_tags = $sites_db.get_ad_tags(hash["campaignId"])
	test_tag = active_ad_tags[0]

	result = $sites_db.get_ad_tag_data(test_tag)

	begin
		ad_tag_cpm = result[0]
	rescue NoMethodError # If the result of the above query is Null...
		FBErrorMessages::Sites.missing_data
		exit
	end
	
	network_name = result[1]
	network_id = result[2]

  creative_ids = $sites_db.get_creatives(hash['campaignId'])

	network_ad_tags_report(network_id, network_name, active_ad_tags, creative_ids)
	
	# ==================
	# Actual tests all go below...
	# ==================
		
  $browser = @config.browser

  $browser.goto(@config.cookie_editor)

  $browser.text_field(:id, "uid").set(%|#{"%02d" %(hash['abTestPerc'].to_i)}|)

  $browser.button(:id, "control").click

  # Go to the page so as to get pixeled by the desired campaign...

  pixel_cutoff = calc_offset_time(@config.offset, 2)

  pixel_url = $browser.get_pixeled(pixel_link, hash['campaign_name'], hash['campaignId'], hash['siteId'])

  # Get contents of pixel log...
  pixel = get_log(@config.pixel_log)
  #puts pixel

  if aff == 0  # Meaning we want to test an affiliate link
    affiliate_redirect_report(@config.affiliate_log, hash, conversion_type, pixel_cutoff)
  end

  # serve an impression...
  imp_cutoff = calc_offset_time(@config.offset, 3)

  $browser.get_impified(@config.imp_seconds, @config.extra_imp_count, active_ad_tags, conversion_type, hash[:url])

  # Success
  success_cutoff = calc_offset_time(@config.offset, 5)

  success_data = $browser.get_success(hash["siteId"])

  success_pixel_log = get_log(@config.pixel_log)

  # Collect info from Conversion log...
  conversion_log = get_log(@config.conversion_log)

  if aff == 0 # Meaning we are using the affiliate link for testing...
    afl_conv_log = get_log(@config.affiliate_log)
  end

  if hash['campaign_name'] == "dynamic"
    product_log = get_product_log(hash['siteId'], pixel_cutoff)
  end

  #Report Results....

  pixel_data = pixel_report(pixel_url, hash["siteId"], hash["campaign_name"], hash['campaignId'], hash['advertiserId'], pixel_cutoff, pixel, test_tag)
  exit if pixel_data == "bad data"

  imp_report_data = impression_report(@config.imp_log, imp_cutoff, hash['campaignId'], active_ad_tags, ad_tag_cpm, hash['cpc'], conversion_type)
  exit if imp_report_data == "bad data"

  success_pixel_report = success_report(success_pixel_log, success_cutoff, hash['siteId'], hash['campaignId'], hash['campaign_name'], hash['advertiserId'], success_data, test_tag)
  exit if success_pixel_report == "no pixel"

  conversion_report(conversion_type, conversion_log, success_cutoff, success_pixel_report, imp_report_data, hash['campaignId'], hash['siteId'])

  if aff == 0
    affiliate_conversion_report(afl_conv_log, pixel_cutoff, hash['siteId'], hash['campaignId'], conversion_type)
  end

  if hash["campaign_name"] =~ /dynamic/i
    product_report(product_log, pixel_cutoff, hash['siteId'])
  end

# We're done!
end 
$browser.close