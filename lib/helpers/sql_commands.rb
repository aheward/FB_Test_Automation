# A namespace that contains all the strings of SQL commands as executable methods

module SQLCommands

  # Used to get sites that are particular pricing models
  # because you can specify that the pricing amount is
  # NOT zero.
  def site_ids_with_pricing(pricing, amount, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId
                    FROM site_data
                    WHERE #{pricing} IS NOT "#{amount}"
                    AND siteId IN (SELECT siteId
                                    FROM creative_data);|)
  end

  def site_ids_in_creative_data(as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId
                  FROM site_data
                  WHERE siteId
                  IN (SELECT siteId
                        FROM creative_data);|)
  end

  def site_data(site_ids, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId, name site_name, url, cpa, cpe, cpm, cpc,
                              revenueShare, abTestPerc, advertiserId, conversionWindow
	                      FROM site_data
	                      WHERE siteId
	                      IN (#{site_ids.join(", ")});|)
  end

  def data_for_a_campaign(campaign_name, site_name, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT s.name site_name, s.siteId, s.url, c.name campaign_name, c.campaignId,
	                  s.cpm, s.cpa, s.revenueShare, s.cpc, s.cpe, s.advertiserId, s.abTestPerc, s.conversionWindow
                    FROM site_data s, campaign_data c
                    WHERE c.siteId = s.siteId
	                  AND c.name = "#{campaign_name}"
	                  AND s.name = "#{site_name}";|)
  end

  def product_url(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT url
                    FROM product_links
                    WHERE siteId = '#{site_id}';|)[0][0]
  end

  def keywords_by_campaign_id(campaign_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT keyword
                    FROM keywords
                    WHERE campaignId = "#{campaign_id}"
                    AND checksum = "";|)
  end

  def full_kwds_by_camp_id(campaign_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT DISTINCT full_keyword
                    FROM keywords
                    WHERE campaignId = "#{campaign_id}"
                    AND full_keyword IS NOT NULL;|)
  end

  def ad_tag_data(test_tag, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT cpm, name, primaryId
                    FROM network_adtag_data
                    WHERE networkAdTagId = "#{test_tag}";|)[0]
  end

  def creatives(campaign_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT creativeId
                    FROM creative_data
                    WHERE campaignId = "#{campaign_id}";|).flatten!
  end

  def creatives_by_site_and_camp(site_id, camp_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT creativeId
                    FROM creative_data
                    WHERE siteId = "#{site_id}"
                    AND campaignId = "#{camp_id}";|).flatten!
  end

  def campaign_from_creative(creative_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    begin
      SITES_DB.execute(%|SELECT campaignId
                    FROM creative_data
                    WHERE creativeId = "#{creative_id}";|)[0][0]
    rescue
      puts "---WARNING: Unable to find the campaign associated with this creative: #{creative_id}!!"
    end
  end

  def camp_name_by_camp_id(camp_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT name
                        FROM campaign_data
                        WHERE campaignId = "#{camp_id}";|)[0][0]
  end

  def cpid_from_sid_and_cpname(site_id, camp_name, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT campaignId
                    FROM campaign_data
                    WHERE siteId = "#{site_id}"
                    AND name = "#{camp_name}";|)[0][0]
  end

  def camp_names_by_sid(site_id, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT name
		                FROM campaign_data
		                WHERE siteId = "#{site_id}";|)
  end

  def spb_for_campaign(campaign_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT showPopularBrowsed
                    FROM site_data
                    WHERE siteId
                    IN (SELECT siteId
                          FROM campaign_data
                          WHERE campaignId = "#{campaign_id}");|)[0][0]
  end

  def product_urls_for_site(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    urls = SITES_DB.execute(%|SELECT url, campaignId
                    FROM product_links
                    WHERE siteId != "#{site_id}";|)
  end

  def ad_tags_for_campaign(campaign_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT networkAdTagId
                    FROM network_adtag_data
                    WHERE campaignId = "#{campaign_id}";|).flatten!
  end

  def ad_tag_ids_by_site_id(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT networkAdTagId
                    FROM network_adtag_data
                    WHERE siteId = "#{site_id}";|)
  end

  def ad_tags_by_site_and_camp(site_id, camp_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT networkAdTagId
		                FROM network_adtag_data
		                WHERE siteId = "#{site_id}"
		                AND campaignId = "#{camp_id}";|)
  end

  def sites_with_control_camps(as_hash=false)
  SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId
                    FROM campaign_data
                    WHERE name = "control";|)
  end

  def control_camp_id(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT campaignID
                    FROM campaign_data
                    WHERE siteId = "#{site_id}"
                    AND name = "control";|)[0][0]
  end

  def non_zero_campaign_data(site_id, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT name campaign_name, campaignId
	                  FROM campaign_data
	                  WHERE siteId = "#{site_id}"
	                  AND NOT (name = "landing" AND performanceWeight == "0.0000");|)
  end

  def network_cpm(ad_tag_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT cpm
                    FROM network_adtag_data
                    WHERE networkAdTagId = "#{ad_tag_id}";|)[0][0]
  end

  def account_id_for_site(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT advertiserId
                    FROM site_data
                    WHERE siteId = "#{site_id}";|)[0][0]
  end

  def sites_with_loyalty_camps(as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT DISTINCT siteId
                    FROM creative_data
                    WHERE campaignId
                    IN (SELECT campaignId
                        FROM campaign_data
                        WHERE name = "loyalty.campaign");|)
  end

  def cukov_data_by_site_name(site_name, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId, name, cookieOverride, showPopularBrowsed
		                FROM site_data
		                WHERE name = "#{site_name}";|)
  end

  def cukov_by_co_and_spb(cookie_override, show_ppl_browsed, as_hash=true)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId, name, cookieOverride, showPopularBrowsed
		                FROM site_data
		                WHERE cookieOverride = '#{cookie_override}'
		                AND showPopularBrowsed = '#{show_ppl_browsed}';|)
  end

  def merits_for_site(site_id, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT period, value
                    FROM vt_merit_data
                    WHERE siteId = "#{site_id}";|)
  end

  def sites_by_window(window, as_hash=false)
    SITES_DB.results_as_hash = as_hash
    SITES_DB.execute(%|SELECT siteId
                        FROM site_data
                        WHERE conversionWindow = "#{window}"
                        AND siteId IN (SELECT siteId FROM creative_data);|)
  end

end
