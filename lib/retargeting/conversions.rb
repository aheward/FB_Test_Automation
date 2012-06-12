module Conversions

  def regression_conversion_test(test_sites, conversion_types)
    tested_sites = []

    test_sites.each do | test_info |
      next if tested_sites.include? test_info["siteId"] # Line to ensure skipping a site if it's already been tested
      #get_pixel_link(test_info)

      # Make the string for the control cookie
      test_info[:control_id] ? control = (test_info['abTestPerc'].to_i - 1) : control = (test_info['abTestPerc'].to_i)
      fb_uid = %|#{"%02d" %(control)}|

      #Create pixel link...
      #pick_affiliate_or_regular(test_info)

      #get ad tag data
      #get_ad_tags_data(test_info)
      #if test_info.data_error?
      #  tested_sites << test_info["siteId"]
      #  next
      #end

      #get_creatives_for_campaign(test_info)

      conversion_types.each do |conv_type|

        visit CookieEditor do |pg|
          pg.set_control_cookie(fb_uid)
        end
        #@browser.dirty(test_info['siteId'], 1, 1)
        @browser.get_pixeled(test_info)

        # Get contents of pixel log...
        get_pixel_log(test_info)

        set_conversion_type(conv_type, test_info)
        conversion_report_header(test_info)
        network_ad_tags_report(test_info)
        affiliate_redirect_report(test_info)
        if test_info.data_error?
          tested_sites << test_info["siteId"]
          FBErrorMessages::Logs.missing_affiliate_event(test_info[:actual_pixel_url])
          next
        end

        @browser.get_impified(test_info)
        if test_info.data_error?
          break
        end

        #@browser.dirty(test_info['siteId'], 1, 1)

        # Success
        @browser.get_success(test_info)
    #exit
        # Collect info from Conversion log, plus affiliate and product logs, if necessary...
        get_conversion_plus(test_info)

        #Report Results....

        pixel_report(test_info)
        if test_info.data_error?
          break
        end

        impression_report(test_info)
        if test_info.data_error?
          break
        end

        success_report(test_info)
        if test_info.data_error?
          break
        end

        conversion_report(test_info)
        affiliate_conversion_report(test_info)
        product_report(test_info)

        @browser.show_cookies
        @browser.cookies.clear
      end

      tested_sites << test_info["siteId"]

    end
    @browser.close
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