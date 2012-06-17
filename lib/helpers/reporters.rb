
module Reporters

  def conversion_report_header(hash)
    site_name = hash['site_name']
    site_id = hash['siteId']
    if hash[:control_id] == nil
      campaign_name = hash['campaign_name']
      campaign_id = hash['campaignId']
    else
      campaign_name = "control"
      campaign_id = hash[:control_id]
    end
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
      puts "Site's Conversion window: #{hash["conversionWindow"]} days"
      puts "\n#{conversion_type.upcase} TEST........."
    end
  end

  def network_ad_tags_report(hash)
    puts "Network: #{hash[:network_name]}  ID: #{hash[:network_id]}"
    puts "Count of active ad tags: #{hash[:active_ad_tags].length}"
    puts "Ad Tag IDS: #{hash[:active_ad_tags].join(", ")}"
    puts "Creative IDS (non-control): #{hash[:creative_ids].join(", ")}"
  end

  def pixel_report(hash)
    if hash[:control_id] == nil
      campaign_name = hash['campaign_name']
    else
      campaign_name = "control"
    end
    puts "\nEvent time: #{hash[:pixel_cutoff]}\tPixel url: #{hash[:actual_pixel_url]}"
    puts "Pixel log, prior to impression or success. #{campaign_name.capitalize} campaign:"

    close_pixel_events = filtrate(hash[:raw_pixel_log], hash[:pixel_cutoff])

    puts close_pixel_events

    target_pixel_event = close_pixel_events.find { | line | line =~ /#{campaign_name}/i }
    begin
      split_pixel_log = split_log(target_pixel_event.chomp, "pixel")
      parse_pixel(split_pixel_log, hash, hash[:test_tag])
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Pixels.no_pixel_fired)
    end
  end

  def affiliate_redirect_report(hash)
    if hash[:affiliate] == 0 # Meaning we want to test an affiliate link
      affiliate = get_log($affiliate_log)
      affiliate_f = affiliate_filtrate(affiliate, hash[:pixel_cutoff])
      affiliate_hash = split_log(affiliate_f[:redirect][0], "affiliate_redirect")
      puts "\nAffiliate Redirect, approx time: #{hash[:pixel_cutoff]}"
      puts affiliate_f[:redirect]
      begin
        parse_affiliate(affiliate_hash, hash)
      rescue NoMethodError
        hash.store(:error, FBErrorMessages::Logs.missing_affiliate_event(hash[:actual_pixel_url]))
      end
    end
  end

  def affiliate_conversion_report(hash)
    if hash[:affiliate] == 0
      puts "\nAffiliate Conversion, approx time: #{hash[:success_cutoff]}"
      afl_conv_log = affiliate_filtrate(hash[:afl_conv_log], hash[:success_cutoff])
      puts afl_conv_log[:conversion]
      afl_conv_hash = split_log(afl_conv_log[:conversion][-1], "affiliate_conversion")
      parse_affiliate(afl_conv_hash, hash)
    end
  end

  def impression_report(hash)
    # get impression log data...
    unless hash[:conv_type] == 'dtc' || hash[:conv_type] == 'otc'

      puts "\nImpression link: #{hash[:creative_link]}\tApprox. time: #{hash[:imp_cutoff]}"
      puts "Click link: #{hash[:click_link]}" if hash[:click_link] != nil
      puts"Event(s):"
      puts hash[:imp_array]

      parse_impression(hash[:split_imp_log], hash['campaignId'], hash)

      click_line = hash[:imp_array].find { | line | line =~ /\tclick\t/ }
      if click_line != nil
        click_hash = split_log(click_line.chomp, "impression")
        parse_impression(click_hash, hash['campaignId'], hash)
      end
      hover_line = hash[:imp_array].find { | line | line =~ /\thover\t/ }
      if hover_line != nil
        hover_hash = split_log(hover_line.chomp, "impression")
        parse_impression(hover_hash, hash['campaignId'], hash)
      end
    end
  end

  def success_report(hash)
    success_array = filtrate(hash[:success_pixel_log], hash[:success_cutoff])
    success_array.keep_if { | lines | lines.to_s.include?("success") }
    begin
      hash[:success_pixel_hash] = split_log(success_array[-1].chomp, "pixel")
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Pixels.no_success_event)
    end
    puts "\nSuccess pixel...  #{hash[:success_data][:link]}\tApprox. time: #{hash[:success_cutoff]}"
    puts "CRV Expected:\t#{hash[:success_data][:crv]}\t\tOID Expected:\t#{hash[:success_data][:oid]}"
    puts "Success events:"
    puts success_array
    parse_pixel(hash[:success_pixel_hash], hash, hash[:test_tag])
  end

  def conversion_report(hash)
    puts "\n#{hash[:conv_type].upcase} conversion:"
    conv = (filtrate(hash[:conversion_log], hash[:success_cutoff]))[-1]
    puts conv
    begin
      hash[:conversion_hash] = split_log(conv.chomp, "conversion")
      hash[:control_id] ? camp = hash[:control_id] : camp = hash['campaignId']
      parse_conversion(hash, camp, hash[:split_imp_log], hash[:success_pixel_hash], hash[:conversion_hash], hash[:conv_type])
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Success.conversion_missing)
    end
  end

  def loyalty_report(hash)
    puts "\nLoyalty impression: #{hash[:creative_link]}\tApprox. time: #{hash[:loyalty_cutoff]}"
    puts hash[:loyalty_imp_array]
    parse_impression(hash[:split_loyalty_imp_log], hash[:loyalty_id], hash)

    puts "\nLoyalty success, approx time: #{hash[:loyalty_success_cutoff]}"
    puts hash[:filtered_loyalty_success]
    parse_pixel(hash[:loyalty_success_pixel_hash], hash, hash[:test_tag])

    puts "\n#{hash[:loyalty_conv_type].upcase} Conversion log for Loyalty:"
    puts hash[:filtered_loyalty_conversion]
    parse_conversion(hash, hash[:loyalty_id], hash[:split_loyalty_imp_log], hash[:loyalty_success_pixel_hash], hash[:loyalty_conversion_hash], hash[:loyalty_conv_type])
  end

  def product_report(hash)
    if hash["campaign_name"] =~ /^dynamic$/i && hash[:control_id] == nil
      puts "\nProduct log:"
      prod = product_filtrate(hash[:product_log], hash[:pixel_cutoff])
      puts prod
      product_hash = split_log(prod[-1], "products")
      #puts "product hash:"
      #p product_hash
      begin
        parse_product(product_hash, hash['siteId'])
      rescue NoMethodError
        hash.store(:error, FBErrorMessages::Products.missing_event)
      end
    end
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
    self.goto DUMMY_PAGE
    browser_cookies = self.cookies.to_a
    expires = browser_cookies[0][:expires]
    puts "\nCookies:"
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