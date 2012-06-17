module DataMakers

  def get_general_test_data(count)
    test_sites = get_generic_test_sites(count)
    test_sites.each do |site|
      get_good_campaign_data(site)
      add_control_perc(site)
    end
    clean_up(test_sites, count)
  end

  def get_landing_test_data(count)
    test_sites = get_generic_test_sites(count)
    test_sites.each do |site_hash|
      campaigns = non_zero_campaign_data(site_hash['siteId'])
      campaigns.delete_if { |item| item["campaign_name"] != "landing" }
      add_camp_to_site(site_hash, campaigns)
      add_control_perc(site_hash)
    end
    clean_up(test_sites, count)
  end

  def get_dynamic_test_data(count)
    test_sites = get_generic_test_sites(count)
    test_sites.each do |site_hash|
      campaigns = non_zero_campaign_data(site_hash['siteId'])
      campaigns.delete_if { |item| item["campaign_name"] != "dynamic" }
      add_camp_to_site(site_hash, campaigns)
      add_control_perc(site_hash)
    end
    clean_up(test_sites, count)
  end

  def get_keyword_test_data(count)
    test_sites = get_generic_test_sites(count)
    test_sites.each do |site_hash|
      campaigns = non_zero_campaign_data(site_hash['siteId'])
      campaigns.delete_if { |item| item["campaign_name"] =~ /abandon/i }
      campaigns.keep_if { |item| item["campaign_name"] != "dynamic" && item["campaign_name"] != "Dynamic" && item["campaign_name"] != "landing" && item["campaign_name"] != "control" && item["campaign_name"] != "loyalty.campaign" }
      add_camp_to_site(site_hash, campaigns)
      add_control_perc(site_hash)
    end
    clean_up(test_sites, count)
  end

  def get_loyalty_test_data(count)
    @blacklist = BlacklistedSites.new.sites
    loyalty_sites = sites_with_loyalty_camps
    loyalty_sites.flatten!
    loyalty_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites = site_data(loyalty_sites)
    test_sites.each do |site|
      get_good_campaign_data(site)
      # Control campaign ID
      site[:loyalty_id] = cpid_from_sid_and_cpname(site["siteId"], "loyalty.campaign")
      loyalty_conv = CONVERSIONS[1..2]
      site[:loyalty_conv_type] = loyalty_conv[rand(2)]
      add_control_perc(site)
    end
    clean_up(test_sites, count)
  end

  def get_merit_test_data(count)
    @blacklist = BlacklistedSites.new.sites
    test_sites = get_sites_by_window
    test_sites << get_sites_by_pricing
    test_sites.flatten!.compact!
    test_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites.shuffle!
    sites_hashes = site_data(test_sites)
    sites_hashes.each do |site|
      get_good_campaign_data(site)
      site_merit_values(site)
      add_control_perc(site)
    end
    clean_up(sites_hashes, count)
  end

  def get_control_test_data(count)
    control_sites = sites_with_control_camps
    @blacklist = BlacklistedSites.new.sites
    control_sites.flatten!
    control_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites = site_data(control_sites)
    test_sites.each do |site|
      get_good_campaign_data(site)
      # Control campaign ID
      site[:control_id] = control_camp_id(site['siteId'])
      add_control_perc(site)
    end
    clean_up(test_sites, count)
  end

  def get_uat_test_data
    @blacklist = BlacklistedSites.new.sites
    uat_sites = uat_site_ids
    uat_sites.flatten!
    uat_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites = site_data(uat_sites)
    test_sites.each do |site|
      get_good_campaign_data(site)
      add_control_perc(site)
    end
    clean_up(test_sites, test_sites.length)
  end

  def set_up_one_site(site_hash)
    get_ad_tags_data(site_hash)
    if site_hash.data_error?
      site_hash[:account_id] = 0
    end

    site_hash[:creative_ids] = creatives_by_site_and_camp(site_hash["siteId"], site_hash["campaignId"])
    if site_hash[:creative_ids] == []
      site_hash[:account_id] = 0
    end
    add_control_perc(site_hash)
    make_pixel_link(site_hash)
    pick_affiliate_or_regular(site_hash)
  end

  def get_ad_tags_data(hash)
    begin
      hash[:active_ad_tags] = ad_tags_for_campaign(hash["campaignId"])
      hash[:active_ad_tags].shuffle!
      hash[:test_tag] = hash[:active_ad_tags][0]
      hash[:creative_link] = tagify(hash[:test_tag])
      tag_data = ad_tag_data(hash[:test_tag])
      hash.store(:ad_tag_cpm, tag_data[0])
      hash.store(:network_name, tag_data[1])
      hash.store(:network_id, tag_data[2])
    rescue NoMethodError
      hash.store(:account_id, 0)
    end
  end

  def get_creatives_for_campaign(hash)
    hash.store(:creative_ids, creatives(hash['campaignId']))
  end

  private

  def get_generic_test_sites(count)
    @blacklist = BlacklistedSites.new.sites
    test_sites = get_sites_by_pricing
    test_sites << get_random_sites(count*3)
    test_sites.flatten!.compact!
    test_sites.delete_if { |item| @blacklist.include?(item) }
    test_sites.shuffle!
    site_data(test_sites)
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

  def get_good_campaign_data(site_hash)
    campaigns = non_zero_campaign_data(site_hash['siteId'])
    campaigns.delete_if { |camp| camp["campaign_name"] == "success" || camp["campaign_name"] == "control" || camp["campaign_name"] =~ /opt.*out/i || camp["campaign_name"] == "loyalty.campaign" || camp["campaign_name"] =~ /abandon/i }
    add_camp_to_site(site_hash, campaigns)
  end

  def add_camp_to_site(site_hash, campaigns)
    campaigns.shuffle!
    begin
      site_hash["campaign_name"] = campaigns[0]["campaign_name"]
      site_hash["campaignId"] = campaigns[0]['campaignId']
    rescue NoMethodError
      site_hash[:account_id] = 0
    end

    set_up_one_site(site_hash)
  end

  def add_control_perc(test_site)
    test_site[:control_id] ? test_site[:control_perc] = %|#{"%02d" %((test_site['abTestPerc'].to_i - 1))}| : test_site[:control_perc] = %|#{"%02d" %((test_site['abTestPerc'].to_i))}|
  end

  def clean_up(sites_hashes, count)
    sites_hashes.delete_if { | site | site[:account_id] == 0 }
    sites_hashes.shuffle!
    sites_hashes[0..count-1]
  end

end