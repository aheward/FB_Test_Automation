
module FBErrorMessages

  module Logs

    def self.no_events_with_ip(ip)
      "The log has no events with your IP in them!!\n\nI think your IP address is:\n\t#{ip}\n\nIf that's correct then there's some other reason\nthe log is missing the expected event.\nIt could be because of a bad Network tag or a cutoff\ntime that's too restrictive.\n\nOf course there's also a good chance that there's actually a bug, here!!"
    end

    def self.no_target_events_past_cutoff(cutoff_time)
      %|The log doesn't have any expected events that
      occur after the specified cutoff time (#{cutoff_time}).\n\n
      You'll want to check the logs manually.
      "Make sure everything's in an Active status, including\nthe Ad Tag and Network.
      When that's confirmed, it's time to start suspecting
      there's a bug, here.|
    end

    def self.missing_affiliate_event(pixel_url)
      %|Expected log event missing!\nCheck that the pixel event fired,\nthat the right pixel was used,\nand whether the affiliate log has expected contents.\n\nPixel URL used: #{pixel_url}\n\nLink(s) to your Affiliate log(s):\n#{$affiliate_log}\n#{$affiliate_log1}|
    end

    def self.unable_to_open_log_file(log)
      "For some reason I can't get to the log file on the server.\nIs the log file located here:\n#{log}"
    end

  end

  module Imps

    def self.no_imp_event
      "Looks like there was no imp event.\nCheck that the Ad Tag used has an\nactive counterpart in the db of the\nbox you're testing.\n\nIt's likely that the ad tag used\nisn't really active on the test box."
    end

    def self.no_active_tags
      "Apparently there are no active Ad Tags?\nI assume this is a problem of bad data\nin the test db.\n\nSkipping this test...\n\n"
    end

  end

  module Pixels

    def self.page_timeout(pixel_link)

    end

    def self.no_pixel_fired
      %|Hmmm... 
      \tIf this was a test of a keyword campaign
      \tthen you're seeing this message because
      \tthe desired campaign pixel didn't fire
      \t(though, presumably, you've been pixeled
      \tfor the landing campaign).
      \tIt's probably because the keyword link is
      \tbeing faked.

      \tThe most common cause is that the site
      \tis doing an auto-redirect (since the URL
      \tisn't real), so the fake URL is immediately
      \tchanged, and thus Fetchback never
      \t'sees' the keyword in the address.

      \tOn the other hand, there's a small chance
      \t(very small) that there could be a
      \tproblem with the keyword code itself.
      \tShould do some focused testing around this
      \tsite and the selected keyword

      \t\tTo (hopefully) prevent seeing this message again
      \t\tin the future for tests of this campaign, you can
      \t\tadd a legitimate keyword url for the campaign id to
      \t\tyour keyword_urls.yml file, found in the lib
      \t\tfolder.|
    end

    def self.no_success_event
      "I can't find the event I'm looking for in the log.\n\nSkipping this test.\n\nYou should make sure there's not a clock problem."
    end

  end

  module Sites

    def self.missing_data
      "Unable to get desired data from the database.\nPlease be sure you're sites.db is in sync with the\nDB being tested."
    end

    def self.no_campaigns
      "Your selected test site doesn't appear to have\nActive landing or dynamic campaigns.\n\nPlease check your test data."
    end

  end

  module Products

    def self.missing_event
      "---There's a problem with the product log. Please investigate."
    end

  end

  module Settings

    def self.config_prod_reg_test
      "Your config file is set to test production.\nHowever, you appear to be running a script made for\nregression testing. Please fix this."
    end

    def self.hosts_is_prod
      "You must point your Hosts file away from production!"
    end

    def self.no_config_yml
      "You need a config.yml file in your config folder!"
    end

  end

end