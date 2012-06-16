module Conversions

  def regression_conversion_test(test_sites, conversion_types)
    tested_sites = []

    test_sites.each do | test_info |
      next if tested_sites.include? test_info["siteId"] # Line to ensure skipping a site if it's already been tested

      conversion_types.each do |conv_type|

        visit CookieEditor do |pg|
          pg.set_control_cookie(test_info[:control_perc])
        end

        #@browser.dirty(test_info['siteId'], rand(3), 2)

        @browser.get_pixeled(test_info)

        set_conversion_type(conv_type, test_info)
        conversion_report_header(test_info)
        network_ad_tags_report(test_info)
        affiliate_redirect_report(test_info)
        if test_info.data_error?
          tested_sites << test_info["siteId"]
          puts test_info[:error]
          next
        end

        @browser.get_impified(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        #@browser.dirty(test_info['siteId'], rand(3), 2)

        # Success
        @browser.get_success(test_info)

        # Collect info from Conversion log, plus affiliate and product logs, if necessary...
        get_conversion_plus(test_info)

        # Tests for Loyalty campaigns...
        if test_info[:loyalty_id] !=nil
          @browser.get_loyalty_impified(test_info)
          #@browser.dirty(test_info['siteId'], rand(3), 2)
          @browser.get_loyalty_success(test_info)
          get_loyalty_logs(test_info)

        end

        #Report Results....

        pixel_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        impression_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        success_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        conversion_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        affiliate_conversion_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        product_report(test_info)
        if test_info.data_error?
          puts test_info[:error]
          break
        end

        if test_info[:loyalty_id] !=nil
          loyalty_report(test_info)
          if test_info.data_error?
            puts test_info[:error]
            break
          end
        end

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