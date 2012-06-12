#!/usr/bin/env ruby
=begin

Tests the DTC, CTC, and VTC conversions for the landing, dynamic, and keyword
campaign types.

This script has one conversion blind spot: It does not test affiliate links with
keyword campaigns.
	
=end
TEST_TYPE = :rt
require '../config/conversion_env'

test_data = get_general_test_data(10)
test_data.each { |s|
  p s['site_name']
  p s['campaign_name']
  p s[:url]
}

regression_conversion_test(test_data, CONVERSIONS)
