#!/usr/bin/env ruby
=begin

Tests the Loyalty Campaign

Things to do:
- Fix the loyalty success to use CTC, VTC, and DTC conversions.
- Refactor with RSpec and Test/Unit when there's time.

=end
TEST_TYPE = :rt
require '../config/conversion_env'

test_sites = get_loyalty_test_data(5)
test_sites.each { |s|
  p s['site_name']
  p s['campaign_name']
  p s[:url]
  p s[:loyalty_id]
  exit
}
exit



# This iterator is the one that goes through the test steps...
test_sites.each do | site |


	

	
	puts ""	
	puts "Loyalty impression:"
	puts filtered_loyalty_log
	parse_impression(loyalty_imp_hash, site[:loyalty_id], site[:ad_tags], site[:ad_tag_cpm], site['cpc'])
	
	puts ""
	puts "Loyalty sucess pixel:"
	puts filtered_loyalty_success_pixel_log
	parse_pixel(loyalty_success_pixel_hash, site['siteId'],  site[:loyalty_id], "loyalty.campaign", site[:account_id], site[:ad_tags][0])
	
	puts ""
	puts "Conversion log for Loyalty:"
	puts filtered_loyalty_conversion_log
	parse_conversion(loyalty_conversion_hash, conversion, loyalty_success_pixel_hash, loyalty_imp_hash, site[:loyalty_id], site['siteId'])
	
	puts "_____________________________________"
	
end 
# We're done!
