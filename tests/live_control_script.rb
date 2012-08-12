=begin

On PRODUCTION, This script tests the CTC and VTC conversions
for a control campaign.

=end
#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

# Add/Remove Site IDs to/from this array if you want to update what
# sites will be tested by this script...
test_site_ids = ['3471']

test_data = site_data(test_site_ids)

test_data.each do |site|
  get_good_campaign_data(site)
  site[:control_id] = control_camp_id(site['siteId'])
  add_control_perc(site)
  make_pixel_link(site)
  pick_affiliate_or_regular(site)
end

test_data.delete_if { | site | site[:account_id] == 0 }

conversion_test(test_data, CONVERSIONS)


