module Impressions

  def get_ad_tags_data(hash)
    begin
      hash[:active_ad_tags] = ad_tags_for_campaign(hash["campaignId"])
      hash[:active_ad_tags].shuffle!
      hash[:test_tag] = hash[:active_ad_tags][0]
      hash[:test_tag_data] = ad_tag_data(hash[:test_tag])
      hash.store(:ad_tag_cpm, hash[:test_tag_data][0])
      hash.store(:network_name, hash[:test_tag_data][1])
      hash.store(:network_id, hash[:test_tag_data][2])
    rescue NoMethodError
      hash[:account] = 0
    end
  end

  def get_creatives_for_campaign(hash)
    hash.store(:creative_ids, creatives(hash['campaignId']))
  end

  def get_impified(hash)
    unless hash[:conv_type] == "dtc" || hash[:conv_type] == "otc"
      active_tags = hash[:active_ad_tags]
      hash[:creative_link] = tagify(hash[:test_tag])

      if $extra_imp_count >= active_tags.length
        count = active_tags.length - 1
      else
        count = $extra_imp_count
      end
      unless count == 0
        1.upto(count) do |x|
          self.goto(tagify(active_tags[x]))
          sleep $imp_seconds
        end
      end
      sleep 2 # Some extra time to help separate test event from dummies
      hash[:imp_cutoff] = calc_offset_time(0)

      self.goto(hash[:creative_link])
      sleep $imp_seconds

      if hash[:conv_type] =~ /ctc/i
        hash[:click_link] = self.clicktrack(hash[:url])
        self.goto(hash[:click_link])

      end
      get_imp_log(hash)

      hash[:imp_array] = filtrate(hash[:raw_imp_log], hash[:imp_cutoff])

      # Here's hoping the ad tag we want is there...
      target = hash[:imp_array].find_all { |line| line =~ /\t#{hash[:test_tag]}\t/ && line =~ /\timp\t/ }

      # fallback...
      generic = hash[:imp_array].find_all { | line | line =~ /\timp\t/ }

      if target.length == 0
        imp_line = generic[0]
      else
        imp_line = target[0]
      end

      begin
        hash.store(:split_imp_log, split_log(imp_line.chomp, "impression"))
      rescue NoMethodError
        FBErrorMessages::Imps.no_imp_event
        hash.store(:error, "bad data")
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