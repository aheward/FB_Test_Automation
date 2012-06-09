#!/usr/bin/env ruby
=begin

Tests the DTC, CTC, and VTC conversions for the landing, dynamic, and keyword
campaign types.

This script has one conversion blind spot: It does not test affiliate links with
keyword campaigns.
	
=end
require '../config/conversion_env'

sites_hashes = get_general_test_data(10)

regression_conversion_test(@config, sites_hashes)