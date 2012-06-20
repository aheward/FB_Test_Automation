module Impressions

  def get_impified(hash)
    unless hash[:conv_type] == "dtc" || hash[:conv_type] == "otc"
      active_tags = hash[:active_ad_tags]

      if hash[:merit30].class == NilClass
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
      end

      hash[:imp_cutoff] = calc_offset_time(FBConfig.get :imp_event)

      self.goto(hash[:creative_link])
      sleep $imp_seconds

      if hash[:conv_type] =~ /ctc/i
        hash[:click_link] = self.clicktrack(hash[:url])
        self.goto(hash[:click_link])

      end

      get_imp_log(hash)

    end
  end

  def get_loyalty_impified(hash)
    hash[:loyalty_cutoff] = calc_offset_time(FBConfig.get :loyalty_imp)
    self.goto(hash[:creative_link])
    sleep $imp_seconds

    if hash[:loyalty_conv_type] =~ /ctc/i
      hash[:loyalty_click_link] = self.clicktrack(hash[:url])
      self.goto(hash[:loyalty_click_link])
    end

    get_loyalty_imp_log(hash)

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