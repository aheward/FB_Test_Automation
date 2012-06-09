module PixImpConv

  # This method builds a site link that is likely (though not guaranteed) to fire off a pixel for
  # the desired campaign.
  def get_link(hash, pixel_page="")
    campaign_name = hash["campaign_name"]
    site_id = hash["siteId"]
    campaign_id =hash["campaignId"]
    site_url = hash["url"]
    revshare = hash["revenueShare"]

    if pixel_page == ""
      begin
        product_url = product_url(site_id)
      rescue NoMethodError
        product_url = "empty"
      end

      special_urls = KeywordURLs.new

      url = case
              when special_urls.by_site.keys.include?(site_id.to_i)
                special_urls.by_site[site_id.to_i]

              else
                if campaign_name =~ /dynamic/i

                  unless product_url == "empty"
                    url = product_url
                  else
                    url = site_url
                  end

                  # If we're testing a landing campaign in a site that is revshare,
                  # then we can still use the product link for testing...
                elsif revshare.to_f > 0 && campaign_name == "landing"

                  unless product_url == "empty"
                    url = product_url
                  else
                    url = site_url
                  end

                elsif campaign_name != "landing"

                  keywords = keywords_by_campaign_id(campaign_id)
                  full = full_kwds_by_camp_id(campaign_id)
                  keywords << full
                  begin
                    keywords.flatten!.shuffle!
                      #p keywords
                  rescue NoMethodError
                    keywords = [campaign_name]
                  end
                  site_url + "?fb_key=#{keywords[0]}"

                else
                  site_url
                end
            end

      # Below is code to force particular URLs for campaigns that are KNOWN
      # to require specific URLs.
      # The idea here should be to extend this list over time, to improve our ability to
      # test keyword campaigns.
      url1 = case
               when special_urls.by_campaign.include?(campaign_id.to_i)
                 special_urls.by_campaign[campaign_id.to_i]
               else
                 url
             end
    else
      pixel_page
    end
  end

  def get_pixeled(hash)
    pixel_link = hash[:url]
    campaign_name = hash["campaign_name"]
    campaign_id = hash["campaignId"]
    site_id =  hash["siteId"]

    self.goto(pixel_link)
    sleep 3 if pixel_link =~ /afl;afc\=/ # Wait extra time for redirect when using affiliate link.
    sleep 2 # Have to wait until pixel should have fired
    if self.html =~ /pixel.fetchback.com/i
      sleep(1) # Hopefully we've been pixeled
    else
      # We need to force the pixel
      puts "Couldn't confirm the pixel was on the target page--meaning here:\n#{pixel_link}\nThis doesn't necessarily mean it wasn't! It's just\nthat 'pixel.fetchback.com' wasn't found in\nthe page HTML."
      key = "&fb_key="

      if campaign_name == "landing" || campaign_name == "dynamic"
        keywords = ["not a keyword campaign"]
      else

        keywords = keywords_by_campaign_id(campaign_id).flatten! # execute(%|SELECT keyword FROM keywords WHERE campaignId = "#{campaign_id}";|).flatten!
        begin
          keywords.shuffle!
        rescue NoMethodError
          keywords = [campaign_name]
        end
        key = "&fb_key=#{keywords[0]}"
      end

      unless pixel_link =~ /afl;afc\=/
        pixel_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=&name=landing&sid=#{site_id}#{key}"
        puts "Just in case, going to this pixel link, too:\n#{pixel_link}"
        self.goto(pixel_link)
        sleep 2
      end

    end
    pixel_link
  end

  def get_ad_tags(campaign_id)
    active_ad_tags = self.get_ad_tags_for_campaign(campaign_id)
    begin
      active_ad_tags.flatten!.shuffle!
    rescue NoMethodError
      FBErrorMessages::Imps.no_active_tags
      return "no tags"
    end
    active_ad_tags
  end

  def get_impified(viewing_seconds, extra_ad_count, active_tags, conversion_type, click_url)
    creative = tagify(active_tags[0])
    self.goto(creative)
    sleep(viewing_seconds)
    puts "Impression link: #{creative}"
    if conversion_type =~ /ctc/i
      click = self.clicktrack(click_url)
      self.goto(click)
      puts "Clicktracking link: #{click}"
    end

    if extra_ad_count >= active_tags.length
      count = active_tags.length - 1
    else
      count = extra_ad_count
    end
    unless count == 0
      1.upto(count) do |x|
        self.goto(tagify(active_tags[x]))
        sleep viewing_seconds
      end
    end

  end

  def get_success(site_id)
    if rand(15) > 0
      crv = "#{rand(500)}"+".#{rand(10)}"+"#{rand(10)}"
    else
      crv = (rand(100) + 1).to_s
    end
    oid = random_nicelink(16)
    success_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=#{random_nicelink}&name=success&sid=#{site_id}" + "&crv=#{crv}" + "&oid=#{oid}"
    self.goto(success_link)
    sleep(2)
    {:link=>success_link, :crv=>crv, :oid=>oid}
  end

  def affiliate_or_regular(site_id, url, campaign_name)
    site_id =

    code = FetchBack.encode_affiliate_param(site_id, 'PPJ1')

    pepperjam_url_1 = "http://pixel.fetchback.com/serve/fb/afl?afc=PPJ1&afx=#{code}&afu="
    pepperjam_url_2 = "http://pixel.fetchback.com/serve/fb/afl;afc=PPJ1,afx=#{code},afu="

    # Pick which one to use...
    z = rand(2)
    if z == 0
      aff_link = pepperjam_url_1 + CGI::escape(url)
    else
      aff_link = pepperjam_url_2 + CGI::escape(CGI::escape(url))
    end
    aff = rand(2)
    if aff == 0 && ( campaign_name == "landing" || campaign_name == "dynamic" )
      pixel_link = aff_link
    else
      pixel_link = url
      aff = 3 # This line is needed to make sure we don't go to affiliate logs later.
    end
    {:pixel=>pixel_link, :x=>aff}
  end

  def calc_imp_code
    if self["cookieOverride"] == 0 || ( self["showPopularBrowsed"] == 0 && self["campaign"] == "dynamic" )
      self["imp_code"] = 4
    elsif self["campaign"] == "landing"
      self["imp_code"] = 1
    elsif self["campaign"] == "dynamic" && self["showPopularBrowsed"] == 1
      self["imp_code"] = 1
    end
  end

  def regression_conversion_test(config, test_sites)
    @config = config
    sites_hashes = test_sites
    tested_sites = []

    puts "*****************************"
    puts "DTC, OTC, CTC, and VTC tests"
    puts "*****************************"

    sites_hashes.each do | hash |
      next if tested_sites.include? hash["siteId"] # Line to ensure skipping a site if it's already been tested
      hash[:url] = get_link(hash)

      #Create pixel link...
      link_info = affiliate_or_regular(hash['siteId'], hash[:url], hash["campaign_name"])
      pixel_link = link_info[:pixel]
      aff = link_info[:x]

      #get ad tag
      active_ad_tags = ad_tags_for_campaign(hash["campaignId"])
      test_tag = active_ad_tags[0]

      result = ad_tag_data(test_tag)

      begin
        ad_tag_cpm = result[0]
      rescue NoMethodError # If the result of the above query is Null...
        tested_sites << hash["siteId"]
        FBErrorMessages::Sites.missing_data
        next
      end

      network_name = result[1]
      network_id = result[2]

      creative_ids = creatives(hash['campaignId'])

      # ==================
      # Actual tests all go below...
      # ==================

      # Conversions iterator...
      CONVERSIONS.each do | conv_type |
        fb_uid = %|#{"%02d" %(hash['abTestPerc'].to_i)}|
        @browser = @config.browser
        visit CookieEditor do |p|
          p.set_control_cookie(fb_uid)
        end

        @browser.dirty(hash['siteId'], 1, 1)
        sleep(4)

        pixel_cutoff = calc_offset_time(@config.offset, 2)

        pixel_url = @browser.get_pixeled(hash)

        # Get contents of pixel log...
        pixel = get_log(@config.pixel_log)

        if conv_type == "dtc" # meaning if we're trying to do a DTC or OTC
          sit_offsets = [ 7175, 7200 ]
          sit_offset = sit_offsets[rand(2)]
          if sit_offset > 7199
            conv_type = "otc"
          else
            # We're still DTC
          end
          visit CookieEditor do |p|
            p.set_otc_offset(hash['siteId'], hash['campaignId'], sit_offset)
          end
        end

        conversion_report_header(hash['site_name'], hash['siteId'], hash['campaign_name'], hash['campaignId'], hash['cpc'],hash['cpm'], hash['cpa'], hash['cpe'], hash['revenueShare'], hash['abTestPerc'], conv_type)
        network_ad_tags_report(network_id, network_name, active_ad_tags, creative_ids)

        if aff == 0  # Meaning we want to test an affiliate link
          affiliate_data = affiliate_redirect_report(@config.affiliate_log, hash, conv_type, pixel_cutoff)
          if affiliate_data == "bad data"
            FBErrorMessages::Logs.missing_affiliate_event(pixel_url,@config.affiliate_log,@config.affiliate_log1)
            next
          end
        end

        # If it's a VTC or CTC, then serve an impression...
        imp_cutoff = calc_offset_time(@config.offset, 3)
        unless conv_type == "dtc" || conv_type == "otc"

          @browser.get_impified(@config.imp_seconds, @config.extra_imp_count, active_ad_tags, conv_type, hash[:url])

        end

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

        pixel_data = pixel_report(pixel_url, hash['siteId'], hash['campaign_name'], hash['campaignId'], hash['advertiserId'], pixel_cutoff, pixel, test_tag)
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

end # PixImpConv

module MeritMethods

  def site_merit_values(hash)
    merit_values = merits_for_site(hash["siteId"])
    begin
      0.upto(3) do |x|
        y = case(x)
              when 0 then :merit1
              when 1 then :merit3
              when 2 then :merit7
              when 3 then :merit30
            end
       hash.store(y, (merit_values[x][1].to_f * 100))
      end
    rescue NoMethodError
      "Error"
    end
  end

end # MeritMethods








