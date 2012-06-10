module Pixel

  # This method builds a site link that is likely (though not guaranteed) to fire off a pixel for
  # the desired campaign.
  def get_pixel_link(hash, pixel_page="")
    campaign_name = hash["campaign_name"]
    site_id = hash["siteId"]
    campaign_id =hash["campaignId"]
    site_url = hash["url"]
    revshare = hash["revenueShare"]

    if pixel_page == ""
      begin
        product_url = product_url(site_id)
      rescue NoMethodError
        product_url = "empty"
      end

      special_urls = KeywordURLs.new

      url = case
              when special_urls.by_site.keys.include?(site_id.to_i)
                special_urls.by_site[site_id.to_i]

              else
                if campaign_name =~ /dynamic/i

                  unless product_url == "empty"
                    url = product_url
                  else
                    url = site_url
                  end

                  # If we're testing a landing campaign in a site that is revshare,
                  # then we can still use the product link for testing...
                elsif revshare.to_f > 0 && campaign_name == "landing"

                  unless product_url == "empty"
                    url = product_url
                  else
                    url = site_url
                  end

                elsif campaign_name != "landing"

                  keywords = keywords_by_campaign_id(campaign_id)
                  full = full_kwds_by_camp_id(campaign_id)
                  keywords << full
                  begin
                    keywords.flatten!.shuffle!
                      #p keywords
                  rescue NoMethodError
                    keywords = [campaign_name]
                  end
                  site_url + "?fb_key=#{keywords[0]}"

                else
                  site_url
                end
            end

      # Below is code to force particular URLs for campaigns that are KNOWN
      # to require specific URLs.
      # The idea here should be to extend this list over time, to improve our ability to
      # test keyword campaigns.
      hash[:url] = case
               when special_urls.by_campaign.include?(campaign_id.to_i)
                 special_urls.by_campaign[campaign_id.to_i]
               else
                 url
             end
    else
      hash.store(:url, pixel_page)
    end
  end

  def get_pixeled(hash)
    pixel_link = hash[:url]
    campaign_name = hash["campaign_name"]
    campaign_id = hash["campaignId"]
    site_id =  hash["siteId"]
    hash[:pixel_cutoff] = calc_offset_time((FBConfig.get :offset), 2)
    self.goto(pixel_link)
    sleep 3 if pixel_link =~ /afl;afc\=/ # Wait extra time for redirect when using affiliate link.
    sleep 2 # Have to wait until pixel should have fired
    if self.html =~ /pixel.fetchback.com/i
      sleep(1) # Hopefully we've been pixeled
    else
      # We need to force the pixel
      puts "Couldn't confirm the pixel was on the target page--meaning here:\n#{pixel_link}\nThis doesn't necessarily mean it wasn't! It's just\nthat 'pixel.fetchback.com' wasn't found in\nthe page HTML."
      key = "&fb_key="

      if campaign_name == "landing" || campaign_name == "dynamic"
        keywords = ["not a keyword campaign"]
      else

        keywords = keywords_by_campaign_id(campaign_id).flatten! # execute(%|SELECT keyword FROM keywords WHERE campaignId = "#{campaign_id}";|).flatten!
        begin
          keywords.shuffle!
        rescue NoMethodError
          keywords = [campaign_name]
        end
        key = "&fb_key=#{keywords[0]}"
      end

      unless pixel_link =~ /afl;afc\=/
        pixel_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=&name=landing&sid=#{site_id}#{key}"
        puts "Just in case, going to this pixel link, too:\n#{pixel_link}"
        self.goto(pixel_link)
        sleep 2
      end

    end
    hash.store(:actual_pixel_url, pixel_link)
  end

  def get_success(hash, log)
    hash[:success_cutoff] = calc_offset_time((FBConfig.get :offset), 2)
    if rand(15) > 0
      crv = "#{rand(500)}"+".#{rand(10)}"+"#{rand(10)}"
    else
      crv = (rand(100) + 1).to_s
    end
    oid = random_nicelink(16)
    success_link = "http://pixel.fetchback.com/serve/fb/pdj?cat=#{random_nicelink}&name=success&sid=#{site_id}" + "&crv=#{crv}" + "&oid=#{oid}"
    self.goto(success_link)
    sleep(2)
    hash.store(:success_pixel_log, get_log(log))
    hash.store(:success_data, {:link=>success_link, :crv=>crv, :oid=>oid})
  end

  def pick_affiliate_or_regular(hash)
    site_id = hash['siteId']
    url = hash[:url]
    campaign_name = hash["campaign_name"]

        code = FetchBack.encode_affiliate_param(site_id, 'PPJ1')

    pepperjam_url_1 = "http://pixel.fetchback.com/serve/fb/afl?afc=PPJ1&afx=#{code}&afu="
    pepperjam_url_2 = "http://pixel.fetchback.com/serve/fb/afl;afc=PPJ1,afx=#{code},afu="

    # Pick which one to use...
    z = rand(2)
    if z == 0
      aff_link = pepperjam_url_1 + CGI::escape(url)
    else
      aff_link = pepperjam_url_2 + CGI::escape(CGI::escape(url))
    end
    aff = rand(2)
    if aff == 0 && ( campaign_name == "landing" || campaign_name == "dynamic" )
      pixel_link = aff_link
    else
      pixel_link = url
      aff = 3 # This line is needed to make sure we don't go to affiliate logs later.
    end
    hash.store(:pixel_info, {:pixel=>pixel_link, :affiliate=>aff})
  end

end