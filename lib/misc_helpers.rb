module MiscHelpers

  def dirty(site_id, count=2, pause=3)
    # Used to intersperse visiting of sites and ads that are NOT the site being tested.
    # The idea is to make sure that events are properly logged to the target site and not to the
    # "dirty" sites.

    plinks = product_url_for_site(site_id)

    plinks.shuffle!

    first_pass = plinks[0..30]

    first_pass.each do | site |

      #get ad tags for the campaign...
      site[2] = ad_tags_for_campaign(site[1])
      site[2].flatten!
    end

    first_pass.delete_if { |x| x[2] == [] }

    to_use = first_pass[0..(count-1)]

    to_use.each do | site |

      #get pixeled...
      begin
        self.goto(site[0])
      rescue
        # Do nothing...
      end
      sleep(1)

      #serve imp...
      begin
        self.goto(tagify(site[2][rand(site[2].length)]))
      rescue Timeout::Error
        #do nothing
      end
      # pause for selected time...
      sleep(pause)

    end

  end

  def get_general_test_data(count) # Note that the count here is for sites IN ADDITION to the pricing cross-section sites.
    sites_hashes = get_test_sites(count)
    sites_hashes.delete_if { |hash| hash["campaign_name"] == "control" }
    sites_hashes.delete_if { |hash| hash["campaign_name"] == "loyalty.campaign" }
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
    sites_hashes.keep_if { |item| item["campaign_name"] != "dynamic" && item["campaign_name"] != "Dynamic" && item["campaign_name"] != "landing" && item["campaign_name"] != "control" && item["campaign_name"] != "loyalty.campaign" }
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