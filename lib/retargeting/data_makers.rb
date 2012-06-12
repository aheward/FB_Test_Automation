module DataMakers

  def get_general_test_data(count) # Note that the count here is for sites IN ADDITION to the pricing cross-section sites.
    test_sites = get_test_sites(count)
    test_sites.delete_if { |hash| hash["campaign_name"] == "control" }
    test_sites.delete_if { |hash| hash["campaign_name"] == "loyalty.campaign" }
    test_sites.each do |site|
      get_ad_tags_data(site)
      if site.data_error?
        site[:account_id] = 0
        next
      end

      #site[:creative_ids] = creatives_by_site_and_camp(site["siteId"], site["campaignId"])
      get_creatives_for_campaign(site)
      if site[:creative_ids] == []
        site[:account_id] = 0
        next
      end

      site[:url] = get_pixel_link(site)
      pick_affiliate_or_regular(site)
    end
    test_sites.delete_if { | site | site[:account_id] == 0 }
    test_sites.shuffle!
    test_sites[0..count-1]
  end

  def get_landing_test_data(count) # Note that the count here is for sites IN ADDITION to the pricing cross-section sites.
    sites_hashes = get_test_sites(count)
    sites_hashes.delete_if { |item| item["campaign_name"] != "landing" }
  end

  def get_dynamic_test_data(count) # Note that the count here is for sites IN ADDITION to the pricing cross-section sites.
    sites_hashes = get_test_sites(count)
    sites_hashes.delete_if { |item| item["campaign_name"] != "dynamic" }
  end

  def get_keyword_test_data(count) # Note that the count here is for sites IN ADDITION to the pricing cross-section sites.
    sites_hashes = get_test_sites(count)
    sites_hashes.delete_if { |item| item["campaign_name"] =~ /abandon/i }
    sites_hashes.keep_if { |item| item["campaign_name"] != "dynamic" && item["campaign_name"] != "Dynamic" && item["campaign_name"] != "landing" && item["campaign_name"] != "control" && item["campaign_name"] != "loyalty.campaign" }
  end

  def get_loyalty_test_data(count)

  end

  def get_control_test_data(count)
    control_sites = sites_with_control_camps
    @blacklist = BlacklistedSites.new.sites
    control_sites.flatten!
    control_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites = control_site_data(control_sites)
    test_sites.each do |site|
      campaigns = non_landing_campaign_data(site['siteId'])
      campaigns.delete_if { |camp| camp["campaign_name"] == "success" || camp["campaign_name"] == "control" || camp["campaign_name"] =~ /opt.*out/i || camp["campaign_name"] == "loyalty.campaign" }
      campaigns.shuffle!
      begin
        site["campaign_name"] = campaigns[0]["campaign_name"]
        site["campaignId"] = campaigns[0]['campaignId']
      rescue NoMethodError
        site[:account_id] = 0
        next
      end

      get_ad_tags_data(site)
      if site.data_error?
        site[:account_id] = 0
        next
      end

      site[:creative_ids] = creatives_by_site_and_camp(site["siteId"], site["campaignId"])
      if site[:creative_ids] == []
        site[:account_id] = 0
        next
      end

      site[:url] = get_pixel_link(site)

      # Control campaign ID
      site[:control_id] = control_camp_id(site['siteId'])

    end
    test_sites.delete_if { | site | site[:account_id] == 0 }
    test_sites.shuffle!
    test_sites[0..count-1]
  end

  def get_test_sites(count)
    @blacklist = BlacklistedSites.new.sites
    test_sites = get_sites_by_pricing
    test_sites << get_sites_by_window
    remainder = count - test_sites.length
    if remainder > 0
      test_sites << get_random_sites(remainder)
    end
    test_sites.flatten!.compact!
    test_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites.shuffle!
    if test_sites.length > count
      number = count
    else
      number = test_sites.length
    end
    sites_hashes = test_site_data(test_sites[0..number])
    sites_hashes.delete_if { |hash| hash["siteId"].to_i == 276 && hash["campaign_name"] != "General Campaign" }# Most BOMGAR campaigns will not test right.
    sites_hashes.shuffle!
  end

  def get_sites_by_pricing
    array = []
    pricing = [ {:pricing=>"revenueShare", :amount=>"0"},
                {:pricing=>"cpm", :amount=>"0.000"},
                {:pricing=>"cpa", :amount=>"0.000"},
                {:pricing=>"cpc", :amount=>"0.000"} ]

    pricing.each do | price |

      items = site_ids_with_pricing(price[:pricing], price[:amount])
      items.shuffle!
      array << items[0..4]

    end
    array
  end

  def get_sites_by_window
    array = []
    WINDOWS.each do | window |
      data = sites_by_window(window)
      data.shuffle!
      array << data[0]
    end
    array
  end

  def get_random_sites(count)
    items = site_ids_in_creative_data
    items.shuffle!
    items[0..count-1]
  end

end