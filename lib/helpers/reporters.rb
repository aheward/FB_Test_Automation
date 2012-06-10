
module Reporters

  def conversion_report_header(hash)
    site_name = hash['site_name']
    site_id = hash['siteId']
    campaign_name =hash['campaign_name']
    campaign_id = hash['campaignId']
    cpc = hash['cpc']
    cpm = hash['cpm']
    cpa = hash['cpa']
    cpe = hash['cpe']
    revenue_share = hash['revenueShare']
    control_perc = hash['abTestPerc']
    conversion_type = hash[:conv_type]

    puts ""
    string =  "| #{site_name} | ID: #{site_id} | #{campaign_name} | Campaign ID: #{campaign_id} |"
    if cpc.to_f > 0
      string << " Site CPC: #{cpc} |"
    end
    if cpm.to_f > 0
      string << " Site CPM: #{cpm} |"
    end
    if cpa.to_f > 0
      string << " Site CPA: #{cpa} |"
    end
    if cpe.to_f > 0
      string << " Site CPE: #{cpe} |"
    end
    if revenue_share.to_f > 0
      string << "Site revshare: #{revenue_share} |"
    end
    border = "+"
    (string.length-2).times { border << "="}
    border << "+"
    puts border
    puts string
    puts border
    if campaign_name == "control"
      puts "Control percentage: #{control_perc}%"
    else
      puts "\n#{conversion_type.upcase} TEST........."
    end
  end

  def network_ad_tags_report(hash)
    puts "Network: #{hash[:network_name]}  ID: #{hash[:network_id]}"
    puts "Count of active ad tags: #{hash[:active_ad_tags].length}"
    puts "Ad Tag IDS: #{hash[:active_ad_tags].join(", ")}"
    puts "Creative IDS (non-control): #{hash[:creative_ids].join(", ")}"
  end

  def pixel_report(pixel_link, hash, event_time, pixel_log, ad_tag)
    site_id = hash['siteId']
    campaign_name = hash['campaign_name']
    campaign_id = hash['campaignId']
    advertiser_id = hash['advertiserId']

    puts "\nPixel url: #{pixel_link}"
    print "Pixel log, prior to impression or success"
    if campaign_name != "control"
      puts ":"
    else
      puts ". #{campaign_name.capitalize} campaign:"
    end
    close_pixel_events = filtrate(pixel_log, event_time)

    puts close_pixel_events

    target_pixel_event = close_pixel_events.find { | line | line =~ /#{campaign_name}/i }
    begin
      pixel_hash = split_log(target_pixel_event.chomp, "pixel")
    rescue NoMethodError
      FBErrorMessages::Pixels.no_pixel_fired
      hash.store(:error, "bad data")
    end
    parse_pixel(pixel_hash, site_id, campaign_id, campaign_name, advertiser_id, ad_tag)
  end

  def affiliate_redirect_report(log, hash)
    if hash[:affiliate] == 0 # Meaning we want to test an affiliate link
      affiliate = get_log(log)
      affiliate_f = affiliate_filtrate(affiliate, hash[:pixel_cutoff])
      affiliate_hash = split_log(affiliate_f[:redirect][0], "affiliate_redirect")
      puts ""
      puts "Affiliate Redirect Entry:"
      puts affiliate_f[:redirect]
      begin
        parse_affiliate(affiliate_hash, hash[:conv_type], hash['siteId'], hash['campaignId'])
      rescue NoMethodError
        hash.store(:error, "bad data")
      end
    end
  end

  def affiliate_conversion_report(log, event_time, site_id, campaign_id, conversion_type)
    puts ""
    puts "Affiliate Conversion Entry:"
    afl_conv_log = affiliate_filtrate(log, event_time)
    puts afl_conv_log[:conversion]
    afl_conv_hash = split_log(afl_conv_log[:conversion][-1], "affiliate_conversion")
    parse_affiliate(afl_conv_hash, conversion_type, site_id, campaign_id)
  end

  def impression_report(log, event_time, campaign_id, ad_tags, ad_tag_cpm, cpc, conversion_type)
    # get impression log data...
    imp_hash = {}
    unless conversion_type == 'dtc' || conversion_type == 'otc'
      imp = get_log(log)
      imp_array = filtrate(imp, event_time)

      # Here's hoping the ad tag we want is there...
      target = imp_array.keep_if { |line| line =~ /\t#{ad_tags[0]}\t/}

      # fallback...
      generic = imp_array.find { | line | line =~ /\timp\t/ }

      if target.length == 0
        imp_line = generic
      else
        imp_line = target[0]
      end

      begin
        imp_hash = split_log(imp_line.chomp, "impression")
      rescue NoMethodError
        FBErrorMessages::Imps.no_imp_event
        "bad data"
      end
      puts ""
      puts "Impression events:"
      puts imp_array

      hover_line = imp_array.find { | line | line =~ /\thover\t/ }

      parse_impression(imp_hash, campaign_id, ad_tags, ad_tag_cpm, cpc)

      click_line = imp_array.find { | line | line =~ /\tclick\t/ }

      if click_line != nil
        click_hash = split_log(click_line.chomp, "impression")
        parse_impression(click_hash, campaign_id, ad_tags, ad_tag_cpm, cpc)
      end

      if hover_line != nil
        hover_hash = split_log(hover_line.chomp, "impression")
        parse_impression(hover_hash, campaign_id, ad_tags, ad_tag_cpm, cpc)

      end
      imp_hash
    end
  end

  def success_report(log, event_time, site_id, campaign_id, campaign_name, advertiser_id, success_data, ad_tag_id)
    success_array = filtrate(log, event_time)
    success_array.keep_if { | lines | lines.to_s.include?("success") }
    begin
      success_pixel_hash = split_log(success_array[-1].chomp, "pixel")
    rescue NoMethodError
      FBErrorMessages::Pixels.no_success_event
      puts "Success cutoff time: #{event_time}"
      puts ""
      return "no pixel"
    end
    puts ""
    puts "Success pixel..."
    puts "Success link: #{success_data[:link]}"
    puts "CRV\t\t\t\t\tOID"
    puts "Expected:\t#{success_data[:crv]}\t\tExpected:\t#{success_data[:oid]}"
    puts success_array
    parse_pixel(success_pixel_hash, site_id, campaign_id, campaign_name, advertiser_id, ad_tag_id)
    success_pixel_hash
  end

  def conversion_report(type, log, event_time, success_pixel_hash, imp_hash, campaign_id, site_id)
    puts ""
    puts "#{type.upcase} conversion:"
    conv = (filtrate(log, event_time))[-1]
    puts conv
    conversion_hash = split_log(conv.chomp, "conversion")

    parse_conversion(conversion_hash, type, success_pixel_hash, imp_hash, campaign_id, site_id)

  end

  def loyalty_report(imp_log, pixel_log, conversion_log, loyalty_imp_time, loyalty_success_time, loyalty_id, ad_tags, cpm, cpc, site_id, advertiser_id)
    raw_loyalty_log = get_log(imp_log)
    filtered_loyalty_log = filtrate(raw_loyalty_log, loyalty_imp_time)
    loyalty_imp_event = filtered_loyalty_log.find { | line | line =~ /\timp\t/ }
    loyalty_imp_hash = split_log(loyalty_imp_event.chomp, "impression")

    raw_loyalty_success_pixel_log = get_log(pixel_log)
    filtered_loyalty_success_pixel_log = filtrate(raw_loyalty_success_pixel_log, loyalty_success_time)
    loyalty_success_pixel_hash = split_log(filtered_loyalty_success_pixel_log[-1].chomp, "pixel")

    raw_loyalty_conversion_log = get_log(conversion_log)
    filtered_loyalty_conversion_log = filtrate(raw_loyalty_conversion_log, loyalty_success_time)
    loyalty_conversion_hash = split_log(filtered_loyalty_conversion_log[-1].chomp, "conversion")

    puts "\n\nLoyalty impression:"
    puts filtered_loyalty_log
    parse_impression(loyalty_imp_hash, loyalty_id, ad_tags, cpm, cpc)

    puts ""
    puts "Loyalty success pixel:"
    puts filtered_loyalty_success_pixel_log
    parse_pixel(loyalty_success_pixel_hash, site_id, loyalty_id, "loyalty.campaign", advertiser_id, ad_tags[0])

    puts ""
    puts "Conversion log for Loyalty:"
    puts filtered_loyalty_conversion_log
    parse_conversion(loyalty_conversion_hash, conversion, loyalty_success_pixel_hash, loyalty_imp_hash, loyalty_id, site_id)
  end

  def product_report(log, event_time, site_id)
    puts ""
    puts "Product log:"
    prod = product_filtrate(log, event_time)
    puts prod
    product_hash = split_log(prod[-1], "products")
    #puts "product hash:"
    #p product_hash
    begin
      parse_product(product_hash, site_id)
    rescue NoMethodError
      FBErrorMessages::Products.missing_event
    end
    puts ""
  end

  def cookie_override_header(test_site, cookie_override, show_pop_browsed)
    string = "| #{test_site} |"
    border = "+"
    (string.length-2).times { border << "="}
    border << "+"
    puts border
    puts string
    puts border
    puts "Cookie Override: #{cookie_override==1 ? "Yes" : "No"}"
    puts "Show Popular Browsed: #{show_pop_browsed==1 ? "Yes" : "No"}"

  end

  def show_cookies
    browser_cookies = self.cookies.to_a
    expires = browser_cookies[0][:expires]
    puts
    puts "Cookies"
    puts "============"
    COOKIES.each do |cookie|
      print cookie.upcase + ": "
      cookie_hash = browser_cookies.find { |item| item[:name]==cookie }
      begin
        print cookie_hash[:value]
        if cookie_hash[:expires] != expires || cookie_hash[:name]=="uid"
          puts "\tExpires: " + cookie_hash[:expires].strftime("%b %d, %Y %l:%M %P")
        else
          puts
        end
      rescue
        puts "Not found"
      end
    end
  end

end