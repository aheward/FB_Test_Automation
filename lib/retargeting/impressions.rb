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

      #DEBUG CODE ================================
      if DEBUG > 0
        puts "Imp cutoff time: " + hash[:imp_cutoff]
        puts "Imp link: " + hash[:creative_link]
      end
      # ==========================================

      self.goto(hash[:creative_link])
      sleep $imp_seconds

      if hash[:conv_type] =~ /ctc/i

        hash[:click_link] = self.clicktrack(hash[:url])

        # DEBUG CODE =================================
        if DEBUG > 1
          puts "\nThe link to simulate the click:"
          puts hash[:click_link] + "\n"
        end
        # ============================================

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

  # this method makes an impression link based on the passed ad tag id.
  def tagify(ad_tag_id)
    IMP_SERVER + "imp?tid=#{ad_tag_id}"
  end

  # This creates the link that simulates the global clicking of an ad.
  # It would be good at some point to extend this method's capabilities, such that it creates a product-specific click link
  # when testing dynamic campaigns.
  def clicktrack(link="http://www.fetchback.com")

    xrx = self.html[/xrx(=|%3D)\d+/].gsub!("%3D","=")
    crid = self.html[/crid=\d+/]
    tid = self.html[/tid=\d+/]

    # Placeholder code in case we need to use it...
    #escaped_link = CGI::escape(link)
    # click_link = "http://imp.fetchback.com/serve/fb/click?#{xrx}&#{crid}&#{tid}&clicktrack=http://fido.fetchback.com/clicktrack.php%3F%2C&rx=#{escaped_link}"

    click_link = IMP_SERVER + "click?#{xrx}&#{crid}&#{tid}&clicktrack=" + CLICKTRACK

  end

end