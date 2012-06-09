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
# Do not modify anything below
# unless you know what you're doing...
require '../config/conversion_env'

sites_hashes = $sites_db.get_data_for_a_campaign(campaign_name, test_site)

sites_hashes.shuffle!

conversion_type = "dtc"

sites_hashes.each do | hash |

  conversion_report_header(hash['site_name'], hash['siteId'], hash['campaign_name'], hash['campaignId'], hash['cpc'], hash['cpm'], hash['cpa'], hash['cpe'], hash['revenueShare'], hash['abTestPerc'], conversion_type)
	
	# logic for using the correct pixel link based on the selected test campaign...
	# The default is for landing, but otherwise, we go through this code...
  hash[:url] = get_link(hash["campaign_name"], hash["siteId"], hash["campaignId"], hash["url"], hash["revenueShare"], pixel_page )

	#Prepare links for affiliate program...
	link_info = affiliate_or_regular(hash['siteId'], hash[:url], hash["campaign_name"])
  pixel_link = link_info[:pixel]
  aff = link_info[:x]

  @browser = @config.browser

  @browser.goto(@config.cookie_editor)

  @browser.text_field(:id, "uid").set(%|#{"%02d" %(hash['abTestPerc'].to_i)}|)
  @browser.button(:id, "control").click

  # Go to the page so as to get pixeled by the desired campaign...
  pixel_cutoff = calc_offset_time(@config.offset, 2)

  pixel_url = @browser.get_pixeled(pixel_link, hash["campaign_name"], hash["campaignId"], hash["siteId"])

  # Get contents of pixel log...
  pixel = get_log( @config.pixel_log)

  if aff == 0  # Meaning we want to test an affiliate link
    affiliate_redirect_report(@config.affiliate_log, hash, conversion_type, pixel_cutoff)
  end

  # Success
  success_cutoff = calc_offset_time(@config.offset, 5)
  success_data = @browser.get_success(hash["siteId"])

  success_pixel_log = get_log( @config.pixel_log)

  # Collect info from Conversion log...
  conversion_log = get_log(@config.conversion_log)

  if aff == 0 # Meaning we are using the affiliate link for testing...
    afl_conv_log = get_log(@config.affiliate_log)
  end

  if hash['campaign_name'] == "dynamic"
    product_log = get_product_log(hash['siteId'], pixel_cutoff)
  end

  #Report Results....

  pixel_data = pixel_report(pixel_url, hash['siteId'], hash['campaign_name'], hash['campaignId'], hash['advertiserId'], pixel_cutoff, pixel, 0)
  exit if pixel_data == "bad data"

  success_pixel_report = success_report(success_pixel_log, success_cutoff, hash['siteId'], hash['campaignId'], hash['campaign_name'], hash['advertiserId'], success_data, 0)
  exit if success_pixel_report == "no pixel"

  conversion_report(conversion_type, conversion_log, success_cutoff, success_pixel_report, {}, hash['campaignId'], hash['siteId'])

  if aff == 0
    affiliate_conversion_report(afl_conv_log, pixel_cutoff, hash['siteId'], hash['campaignId'], conversion_type)
  end

  if hash["campaign_name"] =~ /dynamic/i
    product_report(product_log, pixel_cutoff, hash['siteId'])
  end

  @browser.close
# We're done!
end 
