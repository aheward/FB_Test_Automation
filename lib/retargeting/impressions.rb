module Impressions

  def get_ad_tags_data(hash)
    hash[:active_ad_tags] = ad_tags_for_campaign(hash["campaignId"])
    begin
      hash[:active_ad_tags].shuffle!
      hash[:test_tag] = hash[:active_ad_tags][0]
      hash[:test_tag_data] = ad_tag_data(hash[:test_tag])
    rescue NoMethodError
      FBErrorMessages::Imps.no_active_tags
      hash.store(:error, "no tags")
    end
    begin
      hash.store(:ad_tag_cpm, hash[:test_tag_data][0])
      hash.store(:network_name, hash[:test_tag_data][1])
      hash.store(:network_id, hash[:test_tag_data][2])
    rescue NoMethodError
      FBErrorMessages::Sites.missing_data
      hash.store(:error, "no ad tag cpm")
    end
  end

  def get_impified(viewing_seconds, extra_ad_count, hash)
    unless hash[:conv_type] == "dtc" || hash[:conv_type] == "otc"
      active_tags = hash[:active_ad_tags]
      creative = tagify(hash[:test_tag])

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
      hash[:imp_cutoff] = calc_offset_time((FBConfig.get :offset), 3)
      self.goto(creative)
      sleep(viewing_seconds)
      puts "Impression link: #{creative}"
      if hash[:conv_type] =~ /ctc/i
        click = self.clicktrack(hash[:url])
        self.goto(click)
        puts "Clicktracking link: #{click}"
      end
    end
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

end