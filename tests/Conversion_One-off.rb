#!/usr/bin/env ruby
# Modify these variables to select
# the conversion type, site, and campaign you want to test...
# Note that if you select a DTC conversion there's a 50% chance
# the test run will be for OTC.

# Obviously the names must match EXACTLY...

conversion_type = "ctc" # Must be lower-case and match dtc, vtc, or ctc
test_site       = "Kansas City Steaks"
campaign_name   = "landing"

# If you need to test a special pixel page, define it here.
# This URL will be used instead of the default URL.
# If you aren't going to specify a URL, make sure this line reads: pixel_page = ""
pixel_page = ""

# =========================
TEST_TYPE = :rt
require '../config/conversion_env'
test_site = data_for_a_campaign(campaign_name, test_site)

regression_conversion_test(@config, test_site, [conversion_type])