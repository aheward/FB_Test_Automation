#!/usr/bin/env ruby
# Modify these variables to select the site and non-loyalty
# campaign you want to test with Loyalty.
# WARNING: This should go without saying, but this script will
# fail if you pick a test site that does not have an active
# Loyalty campaign.

# Obviously the names must match EXACTLY...

conversion_type = "vtc" # Must be lower-case, in quotes, and match dtc, vtc, or ctc
loyalty_conversion = "ctc" # Must be "vtc" or "ctc"
test_site = "EnviroInks"
campaign_name = "landing"

# If you need to test a special pixel page, define it here.
# This URL will be used instead of the default URL.
# If you aren't going to specify a URL, make sure this line reads: PIXEL_PAGE = ""
PIXEL_PAGE = "http://www.enviroinks.com/Compatible-Dell-JP453-Series-11-HIGH-YIELD-Color-Ink-Cartridge-150227.html"

# =========================
# Do not modify anything below
# unless you know what you're doing...
TEST_TYPE = :rt
require '../config/conversion_env'

test_data = data_for_a_campaign(campaign_name, test_site)
set_up_one_site(test_data[0])
test_data[0][:loyalty_id] = cpid_from_sid_and_cpname(test_data[0]['siteId'], "loyalty.campaign")
test_data[0][:loyalty_conv_type] = loyalty_conversion
conversion_test(test_data, [conversion_type])


