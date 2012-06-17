module FBHelpers

  def dirty(site_id, count=2, pause=3)
    # Used to intersperse visiting of sites and ads that are NOT the site being tested.
    # The idea is to make sure that events are properly logged to the target site and not to the
    # "dirty" sites.

    plinks = product_urls_for_site(site_id)
    plinks.shuffle!

    first_pass = plinks[0..30]

    first_pass.each do | site |
      #get ad tags for the campaign...
      site[2] = ad_tags_for_campaign(site[1])
    end

    first_pass.delete_if { |site| site[2] == nil } # Delete the site entry if there aren't active ad tags

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

  def site_merit_values(hash)
    merit_values = merits_for_site(hash["siteId"])
    begin
      0.upto(3) do |x|
        y = case(x)
              when 0 then :merit1
              when 1 then :merit3
              when 2 then :merit7
              when 3 then :merit30
            end
        hash.store(y, (merit_values[x][1].to_f * 100))
      end
    rescue NoMethodError
      hash.store(:error=>"Unable to find merit values for site.")
    end
  end

  def data_error?
    self[:error].class == String
  end

end