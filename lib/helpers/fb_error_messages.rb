
module FBErrorMessages

  module Logs

    def self.no_events_with_ip(ip)
      puts "The log has no events with your IP in them!!"
      puts "\nI think your IP address is:\n\t#{ip}"
      puts
      puts "If that's correct then there's some other reason\nthe log is missing the expected event."
      puts "It could be because of a bad Network tag or a cutoff"
      puts "time that's too restrictive.\n\n"
      puts "Of course there's also a good chance that there's actually a bug, here!!"
    end

    def self.no_target_events_past_cutoff(cutoff_time)
      puts "The log doesn't have any expected events that"
      puts "occur after the specified cutoff time (#{cutoff_time}).\n\n"
      puts "You'll want to check the logs manually."
      puts "Make sure everything's in an Active status, including\nthe Ad Tag and Network."
      puts "When that's confirmed, it's time to start suspecting"
      puts "there's a bug, here."
    end

    def self.missing_affiliate_event(pixel_url)
      puts "Expected log event missing!\nCheck that the pixel event fired,\nthat the right pixel was used,\nand whether the affiliate log has expected contents."
      puts "\n\nPixel URL used: #{pixel_url}\n\n"
      puts "Link(s) to your Affiliate log(s):"
      puts $affiliate_log
      puts $affiliate_log1
    end

    def self.unable_to_open_log_file(log)
      puts "For some reason I can't get to the log file on the server.\nIs the log file located here:"
      puts log
    end

  end

  module Imps

    def self.no_imp_event
      puts "Looks like there was no imp event.\nCheck that the Ad Tag used has an\nactive counterpart in the db of the"
      puts "box you're testing."
      puts
      puts "It's likely that the ad tag used\nisn't really active on the test box."
    end

    def self.no_active_tags
      puts "Apparently there are no active Ad Tags?"
      puts "I assume this is a problem of bad data"
      puts "in the test db."
      puts ""
      puts "Skipping this test..."
      puts
    end

  end

  module Pixels

    def self.page_timeout(pixel_link)

    end

    def self.no_pixel_fired
      puts ""
      puts "Hmmm... "
      puts "\tIf this was a test of a keyword campaign"
      puts "\tthen you're seeing this message because"
      puts "\tthe desired campaign pixel didn't fire"
      puts "\t(though, presumably, you've been pixeled"
      puts "\tfor the landing campaign)."
      puts "\tIt's probably because the keyword link is"
      puts "\tbeing faked."
      puts ""
      puts "\tThe most common cause is that the site"
      puts "\tis doing an auto-redirect (since the URL"
      puts "\tisn't real), so the fake URL is immediately"
      puts "\tchanged, and thus Fetchback never"
      puts "\t'sees' the keyword in the address."
      puts ""
      puts "\tOn the other hand, there's a small chance"
      puts "\t(very small) that there could be a"
      puts "\tproblem with the keyword code itself."
      puts "\tShould do some focused testing around this"
      puts "\tsite and the selected keyword"
      puts
      puts "\t\tTo (hopefully) prevent seeing this message again"
      puts "\t\tin the future for tests of this campaign, you can"
      puts "\t\tadd a legitimate keyword url for the campaign id to"
      puts "\t\tyour keyword_urls.yml file, found in the lib"
      puts "\t\tfolder."
    end

    def self.no_success_event
      puts "I can't find the event I'm looking for in the log."
      puts ""
      puts "Skipping this test."
      puts ""
      puts "You should make sure there's not a clock problem."
    end

  end

  module Sites

    def self.missing_data
      puts "Unable to get desired data from the database.\nPlease be sure you're sites.db is in sync with the\nDB being tested."
    end

    def self.no_campaigns
      puts "Your selected test site doesn't appear to have\nActive landing or dynamic campaigns.\n\nPlease check your test data."
    end

  end

  module Products

    def self.missing_event
      puts "---There's a problem with the product log. Please investigate."
    end

  end

end