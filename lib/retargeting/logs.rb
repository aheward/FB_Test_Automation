module Logs

  # This method is used to filter out affiliate log events that you're not interested in.
  # It's like the "filtrate" method but it's needed because the affiliate log is unlike the other logs.
  def affiliate_filtrate(log, cutoff_time)

    items_i_did = [] # defining the list of all log items you're responsible for

    if log !~ /#{$local_ip}/
      puts FBErrorMessages::Logs.no_events_with_ip($local_ip)
    end

    log.each_line do | log_entry |
      if log_entry.include?($local_ip)
        items_i_did << log_entry
      end
    end

    the_items_we_want = {:redirect=>[], :conversion=>[]} # Narrowing down the list to only the items for the last test

    items_i_did.each do | log_entry |
      log_entry_time = log_entry[16..24]
      action = log_entry[/(redirect|conversion)/]
      #p action
      if log_entry_time > cutoff_time == true && action == "redirect"
        the_items_we_want[:redirect] << log_entry
      elsif log_entry_time > cutoff_time == true && action == "conversion"
        the_items_we_want[:conversion] << log_entry
      end

    end

    if the_items_we_want[:redirect].empty? == true && the_items_we_want[:conversion].empty? == true  # Want to try to make sure the list isn't totally empty
      puts "--- Problem with affiliate log! (unless this was your first affiliate test in a while)"
      puts FBErrorMessages::Logs.no_target_events_past_cutoff(cutoff_time)
    end

    the_items_we_want

  end

  def filtrate(log, cutoff_time)
    # This takes the raw log file and eliminates all events that occurred prior to the time of the
    # event you're interested in.

    items_i_did = [] # defining the list of all log items you're responsible for

    if log !~ /\s#{$local_ip}\s/
      puts FBErrorMessages::Logs.no_events_with_ip($local_ip)
    end

    log.each_line do | log_entry |
      if log_entry.include?($unique_id)
        items_i_did << log_entry
      end
    end

    if items_i_did.length == 0
      puts FBErrorMessages::Logs.no_uid_events
    end

    the_items_we_want = [] # Narrowing down the list to only the items for the last test

    items_i_did.each do | log_entry |
      log_entry_time = log_entry[16..24]
      if log_entry_time >= cutoff_time
        the_items_we_want << log_entry
      end
    end

    if the_items_we_want.length == 0 # Want to try to make sure the list isn't totally empty
      puts FBErrorMessages::Logs.no_target_events_past_cutoff(cutoff_time)
    end

    the_items_we_want
  end

  def get_log(log)
    # grabs the desired log file for analysis
    log1 = case(log)
             when $pixel_log then $pixel_log1
             when $imp_log then $imp_log1
             when $conversion_log then $conversion_log1
             when $affiliate_log then $affiliate_log1
             when $product_log then $product_log1
             when $proxy_log then $proxy_log1
             else
               #nothing
           end

    begin
      log_entries = open(log).read
    rescue SocketError
      puts FBErrorMessages::Logs.unable_to_open_log_file(log)
      exit
    end

    if $test_site =~ /#{CLUSTER}/
      begin
        log_entries1 = open(log1).read #URI.parse(log1).read
      rescue SocketError
        puts FBErrorMessages::Logs.unable_to_open_log_file(log1)
        exit
      end
      log_entries << log_entries1
    end
  end

  def get_pixel_log(hash)
    hash.store(:raw_pixel_log, get_log($pixel_log))
    if hash[:control_id] == nil
      campaign_name = hash['campaign_name']
    else
      campaign_name = "control"
    end
    hash[:close_pixel_events] = filtrate(hash[:raw_pixel_log], hash[:pixel_cutoff])
    hash[:target_pixel_event] = hash[:close_pixel_events].find { | line | line =~ /#{campaign_name}/i }

    begin
      hash[:split_pixel_log] = split_log(hash[:target_pixel_event].chomp, "pixel")
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Pixels.no_pixel_fired)
    end

  end

  def get_imp_log(hash)
    hash.store(:raw_imp_log, get_log($imp_log))

    hash.store(:imp_array, filtrate(hash[:raw_imp_log], hash[:imp_cutoff]))

    imp_line = get_target_imp_event(hash[:imp_array], hash[:test_tag])

    begin
      hash.store(:split_imp_log, split_log(imp_line.chomp, "impression"))
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Imps.no_imp_event)
    end
  end

  def get_loyalty_imp_log(hash)
    hash.store(:raw_loyalty_imp_log, get_log($imp_log))  
    hash.store(:loyalty_imp_array, filtrate(hash[:raw_loyalty_imp_log], hash[:loyalty_cutoff]))
    imp_line = get_target_imp_event(hash[:loyalty_imp_array], hash[:test_tag])
    begin
      hash.store(:split_loyalty_imp_log, split_log(imp_line.chomp, "impression"))
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Imps.no_imp_event)
    end
  end

  def get_conversion_plus(hash)
    hash[:conversion_log] = get_log($conversion_log)
    hash[:afl_conv_log] = ""
    if hash[:affiliate] == 0 # Meaning we are using the affiliate link for testing...
      hash[:afl_conv_log] = get_log($affiliate_log)
    end
    hash[:product_log] = ""
    if hash['campaign_name'] =~ /dynamic/i
      hash[:product_log] = get_product_log(hash)
    end
  end
  
  def get_product_log(hash)

    product_log = get_log($product_log)

    array = []
    product_log.each_line do | line |
      if line =~ /\t#{hash['siteId']}/
        array << line
      end
    end
    array.delete_if  { | lines | (lines.to_s)[16..24] < hash[:pixel_cutoff]  }
    array
  end

  def get_loyalty_logs(hash)
    hash.store(:raw_loyalty_success_pixel_log, get_log($pixel_log))
    hash.store(:filtered_loyalty_success, filtrate(hash[:raw_loyalty_success_pixel_log], hash[:loyalty_success_cutoff]))
    hash.store(:loyalty_success_pixel_hash, split_log(hash[:filtered_loyalty_success][-1].chomp, "pixel"))
    hash.store(:raw_loyalty_conversion_log, get_log($conversion_log))
    hash.store(:filtered_loyalty_conversion, filtrate(hash[:raw_loyalty_conversion_log], hash[:loyalty_success_cutoff]))
    begin
      hash.store(:loyalty_conversion_hash, split_log(hash[:filtered_loyalty_conversion][-1].chomp, "conversion"))
    rescue NoMethodError
      hash.store(:error, FBErrorMessages::Success.loyalty_conversion)
    end
  end

  # TODO - Add support for campaign ID.
  def parse_affiliate(affiliate_hash, hash)
    conversion = hash[:conv_type]
    site_id = hash['siteId']
    # This method takes an affiliate log event (that's been converted into a hash via the split_log method)
    # and evaluates whether or not the event has the expected attributes, based on what was tested.

    #p affiliate_hash

    puts "---Something's up with the affiliate log!" if affiliate_hash[:level] != "INFO"
    puts "---Affiliate log date is off! Log date: #{affiliate_hash[:date]}, Today's date: #{Time.now.strftime('%Y-%m-%d') }" if affiliate_hash[:date] != Time.now.strftime("%Y-%m-%d")
    # :hostname=>"vm-qa-pixel02"
    # :uid=>"1296902752006:0165304679398249"
    puts "---Wrong site ID in affiliate log!" if affiliate_hash[:site_id].to_i  != site_id.to_i

    # :campaign_id=>"8187"
    # :affiliate_string=>"PPJ1:1296902752"}

    case
      when affiliate_hash[:action] == "afl_conversion"

        puts "---Wrong conversion type in the affiliate log!" if affiliate_hash[:conversion_type] != conversion

      when affiliate_hash[:action] == "afl_redirect"

      else
        # wow something is wrong
    end

  end

  # This method takes the hash of the conversion log (made using the split_log method)
  # and checks that the event matches expectations by comparing it to all the other data passed into it.
  def parse_conversion(test_info_hash, campaign_id, imp_event_hash, success_event_hash, conversion_hash, conversion_type)
    site_id = test_info_hash['siteId']

    puts "Latest impression time: #{Time.at(conversion_hash[:latest_imp_time].to_i)}" if conversion_hash[:latest_imp_time].to_i != 0
    puts "Latest Pixel time: #{Time.at(conversion_hash[:latest_pixel_time].to_i)}" if conversion_hash[:latest_pixel_time].to_i != 0
    puts "Site impression count: #{conversion_hash[:site_imp_count]}"
    puts "Creative ID: #{conversion_hash[:creative_id]}" if conversion_hash[:creative_id].to_i != 0
    puts "Credited campaign: #{conversion_hash[:campaign_name]}"
    puts "---Wrong site ID in conversion log!" if conversion_hash[:site_id].to_i != site_id.to_i
    # This "unless" clause is because I want to do specific conversion checks when DTC...
    # ...or if we're doing a test of Loyalty. Need to be vigilant about the conversion type in that case.
    unless conversion_hash[:conversion_type] == "dtc" || conversion_hash[:campaign_name] == "loyalty.campaign"
      puts "---Unexpected Conversion Type!" if conversion_type != conversion_hash[:conversion_type]
    end
    puts "---Revenue inconsistency: #{conversion_hash[:client_revenue]} -- #{success_event_hash[:order_revenue]}" if success_event_hash[:order_revenue].to_f != conversion_hash[:client_revenue].to_f
    puts "---Conflicting first site time! Conversion Log's time: #{Time.at(conversion_hash[:first_site_visit].to_i)}, Pixel log's time: #{Time.at(success_event_hash[:first_site_visit_time].to_i)}" if conversion_hash[:first_site_visit] != success_event_hash[:first_site_visit_time]
    puts "---Conflicting order ID! #{conversion_hash[:order_id]} #{success_event_hash[:order_id]}" if conversion_hash[:order_id] != success_event_hash[:order_id]
    puts "---Conversion log date is off! Log date: #{conversion_hash[:date]}, Today's date: #{Time.now.strftime('%Y-%m-%d') }" if conversion_hash[:date] != Time.now.strftime("%Y-%m-%d")
    puts "---Something's up with the conversion log!" if conversion_hash[:level] != "INFO" || conversion_hash[:geo] != "1"

    case
      when conversion_hash[:conversion_type] == "dtc"

        if conversion_hash[:site_imp_count].to_i > 0 && conversion_hash[:latest_imp_time] == "" && merit30 != -1
          puts "Looks like the imp was served outside the Site's conversion window."
        elsif conversion_hash[:site_imp_count].to_i > 0 && merit30 == -1
          puts "---Imp count is not zero, so something is wacky."
          puts "\tCheck the Site's conversion window against the latest imp time."
        else
          puts "Site cookie: #{conversion_hash[:site_cookie]}"
        end

      when conversion_hash[:conversion_type] == "vtc"

        imp_time = Time.now - Time.at(conversion_hash[:latest_imp_time].to_i)
        puts "Impression offset: ~#{(imp_time/86400).to_i} days"

        if test_info_hash[:merit30].class == Float
          case(imp_time)
            when 604800.0..7776000.0
              merit = test_info_hash[:merit30]
              puts "Expected percentage: #{test_info_hash[:merit30]}%"
            when 259200.0..604800.0 then
              merit = test_info_hash[:merit7]
              puts "Expected percentage: #{test_info_hash[:merit7]}%"
            when 86400.00..259200.0 then
              merit = test_info_hash[:merit3]
              puts "Expected percentage: #{test_info_hash[:merit3]}%"
            when 0.0..86400.0 then
              merit = test_info_hash[:merit1]
              puts "Expected percentage: #{test_info_hash[:merit1]}%"
            else
              100
          end

          if conversion_hash[:merit].to_f*100.0 != merit
            puts "---Wrong merit!!!"
            puts "Log reports: #{conversion_hash[:merit].to_f*100.0}%"
          end
        end
        if conversion_hash[:campaign_id].to_i  != campaign_id.to_i && imp_event_hash[:return_code] != "2002"
          puts "---Unexpected campaign ID in the conversion log - #{conversion_hash[:campaign_id]}. Please compare with imp log results."
        elsif conversion_hash[:campaign_id].to_i  != campaign_id.to_i && imp_event_hash[:return_code] == "2002"
          puts "---Ad Tag Preview mode is messing up this test."
        end

        puts "Merit percentage: #{conversion_hash[:merit].to_f*100.0}%"
        puts "Ad Tag ID: #{conversion_hash[:network_ad_tag]}"
        puts "Campaign Cookie: #{conversion_hash[:campaign_cookie]}"
        puts "Creative Cookie: #{conversion_hash[:creative_cookie]}"
        puts "---Strange UID problem!" if success_event_hash[:uid] != imp_event_hash[:uid]
        puts "---Strange UID problem!" if conversion_hash[:uid] != imp_event_hash[:uid]

      when conversion_hash[:conversion_type] == "ctc"

        puts "Click Cookie: #{conversion_hash[:click_cookie]}"
        puts "---Strange UID problem!" if success_event_hash[:uid] != imp_event_hash[:uid]
        puts "---Strange UID problem!" if conversion_hash[:uid] != imp_event_hash[:uid]
        if conversion_hash[:campaign_id].to_i  != campaign_id.to_i && imp_event_hash[:return_code] != "2002"
          puts "---Unexpected campaign ID in the conversion log - #{conversion_hash[:campaign_id]}. Please compare with imp log results."
        elsif conversion_hash[:campaign_id].to_i  != campaign_id.to_i && imp_event_hash[:return_code] == "2002"
          puts "---Ad Tag Preview mode is messing up this test."
        end

      when conversion_hash[:conversion_type] == "otc"

        puts "Site Cookie: #{conversion_hash[:site_cookie]}"

      else
        #wow something is really wrong!
    end

    # :conversion_box=>"vm-qa-pixel02",

  end

  def parse_impression(imp_hash, campaign_id, hash)
    ad_tag_ids = hash[:active_ad_tags]
    cpm = hash[:ad_tag_cpm]
    cpc = hash['cpc']
    # This method takes the hash of the impression log (made using the split_log method)
    # and compares it to the other items to evaluate whether the event matches expectations.

    #p imp_hash

    case
      when imp_hash[:event] == "imp"
        begin
          creative_campaign_id = campaign_from_creative(imp_hash[:creative_id])
          camp_name = camp_name_by_camp_id(creative_campaign_id)
        rescue
          camp_name = ""
        end
        if camp_name != ""
          spb = spb_for_campaign(creative_campaign_id)
        else
          camp_name = "Unknown"
          spb = 'x'
        end
        if camp_name == "control"
          puts "Served a Control ad."
        elsif camp_name == "Default"
          puts "---Something is wrong. You've been served a Default PSA."
          puts "Check:"
          puts "1) That your test DB is in sync with the system you're testing."
          puts "2) That there's an Active creative associated with the given Ad Tag."
          puts "3) That you actually got pixeled for the site/campaign."

        elsif spb == 1
          puts "NOTE: The Creative served was from the #{camp_name} campaign (ID: #{creative_campaign_id})." if creative_campaign_id.to_i != campaign_id.to_i
        elsif spb =='x'
          puts "NOTE: Can't determine the campaign based on the Impression served.\nDoes the sites.db file need to be updated?"
        else
          puts "---NOTE: The Creative served was from the #{camp_name} campaign (ID: #{creative_campaign_id}), not the one you're testing. Just pointing it out. Generally not a problem." if creative_campaign_id.to_i != campaign_id.to_i
        end

        puts "Return code: #{imp_hash[:return_code]} - #{return_code(imp_hash[:return_code])}"
        puts "---Unexpected Ad Tag ID in the log: #{imp_hash[:adtag_id]}"  if imp_hash != {} && ad_tag_ids.include?(imp_hash[:adtag_id]) == false
        puts "---Something's up with the impression log!" if imp_hash[:level] != "INFO" || imp_hash[:geo] != "1"
        puts "---Imp log date is off! Log date: #{imp_hash[:date]}, Today's date: #{Time.now.strftime('%Y-%m-%d') }" if imp_hash[:date] != Time.now.strftime("%Y-%m-%d")
        puts "---Ad Tag CPM problem? - CPM: #{cpm.to_f} log: #{imp_hash[:cost].to_f * 1000}" if (cpm.to_f*100).round(0).to_i != (imp_hash[:cost].to_f * 100000).round(0).to_i unless imp_hash[:return_code].to_i==1005

      when imp_hash[:event] == "interaction"

      when imp_hash[:event] == "hover"

      when imp_hash[:event] == "click"

        puts "Creative ID clicked: #{imp_hash[:creative_id]}"
        puts "---Click return code error: #{imp_hash[:return_code]}" if imp_hash[:return_code] != "1001"
        puts "---CPC problem - Site CPC: #{cpc}, Log: #{imp_hash[:revenue]}" if cpc.to_f != imp_hash[:revenue].to_f

      else

    end

    #:uid=>"1296846918430:7583645854610853",
    #	:campaign_history_cookie=>"1_1296846937_8481:5_3090:16_3247:19",
    #:creative_history_cookie=>"1_1296846937_22765:32554:1:0_19183:1:13",
    #:imp_box=>"vm-qa-imp02",
    #:browser=>"Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",

    #:referrer_string=>nil

  end

  def parse_pixel(pixel_hash, hash, adtag_id=0)
    site_id = hash['siteId']
    if hash[:control_id] == nil
      campaign_id = hash['campaignId']
      campaign_name = hash['campaign_name']
    else
      campaign_name = "control"
      campaign_id = hash[:control_id]
    end
    account_id = hash['advertiserId']
    # This method takes the hash of the pixel log (made via the split_log method)
    # and compares it to the rest of the passed information, evaluating whether or not the event's
    # attributes match what's expected.

    #p pixel_hash
    puts "---Wrong Site ID in pixel log! Got: #{pixel_hash[:site_id]} Expected: #{site_id}" if pixel_hash[:site_id].to_i != site_id.to_i
    puts "---Something's up with the pixel log level! #{pixel_hash[:level]}" if pixel_hash[:level] != "INFO"
    puts "---Something's up with the pixel log geoid! #{pixel_hash[:geoid]}" if pixel_hash[:geoid] != "1"
    puts "---Something's up with the pixel log n_a! #{pixel_hash[:n_a]}" if pixel_hash[:n_a] != "n/a"
    puts "---Something's up with the pixel log zero! #{pixel_hash[:zero]}" if pixel_hash[:zero] != "0"
    puts "---Pixel log date is off! Log date: #{pixel_hash[:date]}, Today's date: #{Time.now.strftime('%Y-%m-%d') }" if pixel_hash[:date] != Time.now.strftime("%Y-%m-%d")
    puts "---Wrong account ID in Ad Tag! Advertiser ID: #{pixel_hash[:advertiser_id]} Ad Tag Listing: #{account_id}" if account_id.to_i != pixel_hash[:advertiser_id].to_i
    puts "---Unexpected Last Ad Tag ID! Expected: #{adtag_id} Got:#{pixel_hash[:last_ad_tag_id]}" if pixel_hash[:last_ad_tag_id] != "0" && pixel_hash[:last_ad_tag_id].to_i != adtag_id.to_i

    case
      when pixel_hash[:event] == ("uid" || "pixel") && pixel_hash[:campaign_name] != "success"

        puts "---Wrong Campaign ID in the pixel log! Expecting: #{campaign_id}, #{campaign_name} - Reported: #{pixel_hash[:campaign_id]}, #{pixel_hash[:campaign_name]}" if pixel_hash[:campaign_id].to_i  != campaign_id.to_i

      when pixel_hash[:campaign_name] == "success"
        # At this point do nothing
      when pixel_hash[:event] == "keyword"

        puts "---Wrong Campaign ID in the pixel log! Expecting:#{campaign_id} Reported: #{pixel_hash[:campaign_id]}" if pixel_hash[:campaign_id].to_i  != campaign_id.to_i

      when pixel_hash[:event] =~ /err/
        # At this point do nothing
      else
        # Nothing to see, here.
    end

    puts "Category ID: #{pixel_hash[:category_id]}" if pixel_hash[:category_id] != ""
    #pixel_hash[:campaign_name=>"landing",
    #pixel_hash[:uid=>"1296846868574:6794774187079015",
    #pixel_hash[:pixel_box=>"vm-qa-pixel01",
    puts "Order revenue: #{pixel_hash[:order_revenue]}" if pixel_hash[:order_revenue].to_i != 0
    puts "Order ID: #{pixel_hash[:order_id]}" if pixel_hash[:order_id] != "Unknown"
    puts "Last Creative ID: #{pixel_hash[:last_creative_id]}" if pixel_hash[:last_creative_id].to_i != 0
    puts "Last Creative time: #{Time.at(pixel_hash[:latest_creative_time].to_i)}" if pixel_hash[:latest_creative_time].to_i != 0
    puts "First site visit time: #{Time.at(pixel_hash[:first_site_visit_time].to_i)}" if pixel_hash[:first_site_visit_time].to_i != 0
    puts "Referrer domain: #{pixel_hash[:referrer_domain]}" if pixel_hash[:referrer_domain] != "n/a"
    puts "Last creative hovered: #{pixel_hash[:last_hovered]}" if pixel_hash[:last_hovered].to_i != 0
    puts "Last hover time: #{Time.at(pixel_hash[:last_hover_time].to_i)}" if pixel_hash[:last_hover_time].to_i != 0
    puts "Seconds between visits: #{pixel_hash[:seconds_between_visits]}" if pixel_hash[:seconds_between_visits] != ""

  end

  def parse_product(product_hash, site_id)
    # This method takes the hash of the product log, made using the split_log method
    # and displays the output, so that the tester can decide whether or it meets expectations

    # Future projects:
    # 1) Improve the scripts so that they check the product IDs automatically, no human needed.
    # 2) Set up dummy client web sites so that abandoned and purchased products can be tested. (this is a Jira task right now)

    #p product_hash

    puts "---Something's up with the product log!" if product_hash[:level] !="INFO"
    #product_hash[:date=>"2011-02-05"
    # product_hash[:time=>""
    # product_hash[:uid=>"1296903571961:0453023761656509"
    puts "Last abandoned product: #{product_hash[:abandoned_product]}"
    puts "Last browsed product: #{product_hash[:browsed_product]}"
    puts "Purchased products: #{product_hash[:purchased_product]}"
    puts "Abandoned products: #{product_hash[:all_abandoned]}"
    puts "Browsed products: #{product_hash[:all_browsed]}"
    puts "---Wrong site ID!" if product_hash[:site_id].to_i != site_id.to_i

  end

  def product_filtrate(log, cutoff_time)
    # This method takes the raw product log and culls it down to
    # the last couple events, based on the specified cutoff time.


    the_items_we_want = [] # Narrowing down the list to only the items for the last test

    log.each do | log_entry |
      log_entry_time = log_entry[16..24]

      if log_entry_time > cutoff_time
        the_items_we_want << log_entry
      end
    end

    if the_items_we_want.empty? == true || the_items_we_want == nil  # Want to try to make sure the list isn't totally empty
      the_items_we_want = ["No\tproducts?\tThis may be a problem!"]
    end

    the_items_we_want
  end

  def proxy_filtrate(log, cutoff_time, site_id)
    # This method takes the proxy log and deletes all lines that are prior to the cutoff time
    # and not related to the desired site id.

    items_i_did = [] # defining the list of all log items you're responsible for

    log.each_line do | log_entry |
      if log_entry[25..28].to_i == site_id.to_i
        items_i_did << log_entry
      end
    end

    the_items_we_want = [] # Narrowing down the list to only the items for the last test

    items_i_did.each do | log_entry |
      log_entry_time = log_entry[16..24]

      if log_entry_time > cutoff_time
        the_items_we_want << log_entry
      end
    end

    if the_items_we_want.empty? == true || the_items_we_want == nil  # Want to try to make sure the list isn't totally empty
      the_items_we_want = ["No Feed\tor not\ta\tdynamic\tadvertisement"]
    end

    the_items_we_want
  end

  # This method evaluates the passed code variable.
  # You get this code from the impression log--generally after you've converted it
  # to a hash using the split_log method.
  def return_code(code)

    code.chomp!
    case(code)
      when "10" then "Hover entry"
      when "1000" then "Standard imp"
      when "1001" then "Standard click"
      when "1002" then "Product campaign"
      when "1003" then "Keyword campaign"
      when "1004" then "Loyalty campaign"
      when "1005" then "Control campaign"
      when "1006" then "Site default imp"
      when "1007" then "Cookie Override, no history"
      when "1010" then "Cookie Override with history"
      when "2000" then "Preview imp"
      when "2001" then "Preview click"
      when "2002" then "Preview Ad Tag"
      when "4001" then "Default preview ad tag"
      when "4002" then "Default size unavailable"
      when "4003" then "Default no campaign cookie"
      when "4004" then "Default successed"
      when "4005" then "Default no match"
      when "4006" then "Default unknown error"
      when "4007" then "Something completely weird just happened"
      when "4008" then "Ad Tag Preview, but still shown default"
      when "4010" then "Default other site history"
      when "5000" then "Ad tag javascript"
      when "5003" then "Hover?"
      else "No clue what this return code means!"
    end
  end

  # This method converts a log entry into a hash object according to the
  # specified log type.
  # The idea is to then take the hash object and either parse it or else
  # report the data or use it for additional tests.
  def split_log(entry, log_type)

    unless entry == nil
      array = entry.split("\t")

      hash = {:level => array[0], :date=> array[1],
              :time=> array[2] }

      log_hash = case(log_type)
                   when "pixel" then
                     hash.merge(:ip=> array[3],
                                :event=> array[4],
                                :site_id=> array[5],
                                :category_id=> array[6],
                                :campaign_name=> array[7],
                                :geoid=> array[8],
                                :uid=> array[9],
                                :pixel_box=> array[10],
                                :zero=> array[11],
                                :n_a=> array[12],
                                :order_revenue=> array[13],
                                :order_id=> array[14],
                                :last_creative_id=> array[15],
                                :latest_creative_time=> array[16],
                                :return_visit=> array[17],
                                :first_site_visit_time=> array[18],
                                :referrer_domain=> array[19],
                                :campaign_id=> array[20],
                                :advertiser_id=> array[21],
                                :last_hovered=> array[22],
                                :last_hover_time=> array[23],
                                :seconds_between_visits=> array[24],
                                :last_ad_tag_id=> array[25])
                   when "impression" then
                     hash.merge(:ip=> array[3],
                                :event=> array[4],
                                :creative_id=> array[5],
                                :geo=> array[6],
                                :revenue=> array[7],
                                :cost=> array[8],
                                :uid=> array[9],
                                :adtag_id=> array[10],
                                :campaign_history_cookie=> array[11],
                                :creative_history_cookie=> array[12],
                                :imp_box=> array[13],
                                :browser=> array[14],
                                :return_code=> array[15].chomp,
                                :referrer_string=> array[16])
                   when "conversion" then
                     hash.merge(:ip=> array[3],
                                :conversion_type=> array[4],
                                :site_id=> array[5],
                                :campaign_name=> array[6],
                                :campaign_id=> array[7],
                                :uid=> array[8],
                                :geo=> array[9],
                                :conversion_box=> array[10],
                                :creative_id=> array[11],
                                :latest_imp_time=> array[12],
                                :latest_pixel_time=> array[13],
                                :first_site_visit=> array[14],
                                :network_ad_tag=> array[15],
                                :site_imp_count=> array[16],
                                :client_revenue=> array[17],
                                :order_id=> array[18],
                                :merit=> array[19],
                                :creative_cookie=> array[20],
                                :campaign_cookie=> array[21],
                                :click_cookie=> array[22],
                                :site_cookie=> array[23])
                   when "products" then
                     hash.merge(:uid=> array[3],
                                :abandoned_product=> array[4],
                                :browsed_product=> array[5],
                                :purchased_product=> array[6],
                                :clicked_product=> array[7],
                                :all_abandoned=> array[8],
                                :all_browsed=> array[9],
                                :site_id=> array[10].chomp)
                   when "proxy" then
                     hash.merge(:site_id=> array[3],
                                :product_id=> array[4],
                                :fb_product_id=> array[5],
                                :image_url=> array[6],
                                :exception_class=> array[7],
                                :exception_msg=> array[8],
                                :time_to_load=> array[9],
                                :cached_size=> array[10],
                                :image_status=> array[11])
                   when "affiliate_redirect" then
                     hash.merge(:ip=> array[3],
                                :hostname=> array[4],
                                :action=> array[5],
                                :uid=> array[6],
                                :site_id=> array[7],
                                :affiliate_string=> array[8])
                   when "affiliate_conversion" then
                     hash.merge(:ip=> array[3],
                                :hostname=> array[4],
                                :action=> array[5],
                                :uid=> array[6],
                                :site_id=> array[7],
                                :conversion_type=> array[8],
                                :campaign_id=> array[9],
                                :affiliate_string=> array[10])
                   when "imp_var" then
                     hash.merge(:ip=> array[3],
                                :uid=> array[4],
                                :creative_id=> array[5],
                                :json_object=> array[6])
                   when "form" then
                     hash.merge(:ip=> array[3],
                                :uid=> array[4],
                                :creative_id=> array[5],
                                :json_object=> array[6])
                   else
                     puts "You have a typo in your log type for the parser. Fix it."
                 end
    else
      puts "No logged event (or something)" # TODO - Bring this code up to par
    end
  end

  # This creates the link that simulates the global clicking of an ad.
  # It would be good at some point to extend this method's capabilities, such that it creates a product-specific click link
  # when testing dynamic campaigns.
  def clicktrack(link="http://www.fetchback.com")

    xrx = self.html[/xrx=\d+/]
    crid = self.html[/crid=\d+/]
    tid = self.html[/tid=\d+/]

    # Placeholder code in case we need to use it...
    #escaped_link = CGI::escape(link)
    # click_link = "http://imp.fetchback.com/serve/fb/click?#{xrx}&#{crid}&#{tid}&clicktrack=http://fido.fetchback.com/clicktrack.php%3F%2C&rx=#{escaped_link}"

    click_link = "http://imp.fetchback.com/serve/fb/click?#{xrx}&#{crid}&#{tid}&clicktrack=http://fido.fetchback.com/clicktrack.php%3F%2C"

    #puts click_link
  end

  # Method to parse the link
  # This method is mostly obsolete, but is still used in fido-classes.rb
  # for grabbing the pixel links sub-strings.
  def stripify(string)

    string.sub!("adtag.js", "imp")
    front = string.rindex ("'h")
    string.slice!(0..front)
    back = string.index ("'")
    last = string.length
    string.slice!(back, last)
    string.gsub!("cat=", "cat=#{random_nicelink}")

    # this part is strictly for special testing situations...
    #x = rand(5)
    #if x == 0
    #	string.gsub!("name=landing", "name=#{random_nicelink}")
    #end

    string
  end

  # this method makes an impression link based on the passed ad tag id.
  def tagify(ad_tag_id)
    if TEST_TYPE == :rt
      link = "http://imp.fetchback.com"
    else
      link = "http://#{$test_site_ip}"
    end
    link + "/serve/fb/imp?tid=#{ad_tag_id}"
  end

  def calc_offset_time(local_adjustment)
    (Time.now.utc - $offset.to_i - local_adjustment).strftime("%X")
  end

  private

  def get_target_imp_event(array, test_tag)
    target = array.find_all { |line| line =~ /\t#{test_tag}\t/ && line =~ /\timp\t/ }

    # fallback...
    generic = array.find_all { | line | line =~ /\timp\t/ }
    if target.length == 0
      generic[0]
    else
      target[0]
    end
  end

end