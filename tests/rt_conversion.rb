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
#=begin
test_data.each do |site|
  @browser.goto site[:url]
  sleep 2

end
@browser.show_cookies
puts @browser.unique_identifier

exit
#=end

regression_conversion_test(@config, test_data, CONVERSIONS)
