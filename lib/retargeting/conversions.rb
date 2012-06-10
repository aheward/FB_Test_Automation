module Conversions

  def regression_conversion_test(config, test_sites)
    @config = config
    sites_hashes = test_sites
    tested_sites = []

    puts "*****************************"
    puts "DTC, OTC, CTC, and VTC tests"
    puts "*****************************"

    sites_hashes.each do | hash |
      next if tested_sites.include? hash["siteId"] # Line to ensure skipping a site if it's already been tested
      get_pixel_link(hash)

      # Make the string for the control cookie
      fb_uid = %|#{"%02d" %(hash['abTestPerc'].to_i)}|

      #Create pixel link...
      pick_affiliate_or_regular(hash)

      #get ad tag data
      get_ad_tags_data(hash)
      if hash.data_error?
        tested_sites << hash["siteId"]
        next
      end

      hash[:creative_ids] = creatives(hash['campaignId'])

      # ==================
      # Actual tests all go below...
      # ==================

      # Conversions iterator...
      CONVERSIONS.each do | conv_type |

        @browser = @config.browser
        visit CookieEditor do |pg|
          pg.set_control_cookie(fb_uid)
        end

        @browser.dirty(hash['siteId'], 1, 1)
        sleep(4)

        @browser.get_pixeled(hash)

        # Get contents of pixel log...
        raw_pixel_log = get_log(@config.pixel_log)

        set_conversion_type(conv_type, hash)

        conversion_report_header(hash)
        network_ad_tags_report(hash)
        affiliate_redirect_report(@config.affiliate_log, hash)
        if hash.data_error?
          tested_sites << hash["siteId"]
          FBErrorMessages::Logs.missing_affiliate_event(hash[:actual_pixel_url], @config.affiliate_log, @config.affiliate_log1)
          next
        end

        @browser.get_impified(@config.imp_seconds, @config.extra_imp_count, hash)

        @browser.dirty(hash['siteId'], 1, 1)

        sleep(3)
        # Success
        success_cutoff = calc_offset_time(@config.offset, 5)

        success_data = @browser.get_success(hash["siteId"])

        success_pixel_log = get_log(@config.pixel_log)

        # Collect info from Conversion log...
        conversion_log = get_log(@config.conversion_log)
        afl_conv_log=""
        if aff == 0 # Meaning we are using the affiliate link for testing...
          afl_conv_log = get_log(@config.affiliate_log)
        end
        product_log=""
        if hash['campaign_name'] =~ /dynamic/i
          product_log = get_product_log(hash['siteId'], pixel_cutoff)
        end

        #Report Results....

        pixel_data = pixel_report(pixel_url, hash, pixel_cutoff, pixel, test_tag)
        if pixel_data == "bad data"
          @browser.close
          break
        end

        imp_report_data = impression_report(@config.imp_log, imp_cutoff, hash['campaignId'], active_ad_tags, ad_tag_cpm, hash['cpc'], conv_type)
        if imp_report_data == "bad data"
          @browser.close
          break
        end

        success_pixel_report = success_report(success_pixel_log, success_cutoff,  hash['siteId'], hash['campaignId'], hash['campaign_name'], hash['advertiserId'], success_data, test_tag)
        if success_pixel_report == "no pixel"
          @browser.close
          break
        end

        conversion_report(conv_type, conversion_log, success_cutoff, success_pixel_report, imp_report_data, hash['campaignId'], hash['siteId'])

        if aff == 0
          affiliate_conversion_report(afl_conv_log, pixel_cutoff, hash['siteId'], hash['campaignId'], conv_type)
        end

        if hash["campaign_name"] =~ /dynamic/i
          product_report(product_log, pixel_cutoff, hash['siteId'])
        end

        @browser.show_cookies

        @browser.close

      end

      site_ids << hash["siteId"]

      # We're done!
    end

  end

  def set_conversion_type(conv_type, hash)
    if conv_type == "dtc" # meaning if we're trying to do a DTC or OTC
      sit_offset = CONVERSION_OFFSETS[rand(2)]
      if sit_offset > 7199
        hash[:conv_type] = "otc"
      else
        hash[:conv_type] = conv_type
      end
      visit CookieEditor do |pg|
        pg.set_otc_offset(hash['siteId'], hash['campaignId'], sit_offset)
      end
    else
      hash[:conv_type] = conv_type
    end
  end

end