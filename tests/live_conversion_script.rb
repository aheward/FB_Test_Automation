=begin

On PRODUCTION, This script tests the DTC, CTC, and VTC conversions 
for the landing, dynamic, and keyword campaign types.

=end
#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

campaigns = ["landing", "keyword A"]

test_data = []
campaigns.each do |campaign|
  hash = data_for_a_campaign(campaign, "Site-A")[0]
  camp_id = hash['campaignId']
  hash.store(:active_ad_tags, ad_tags_for_campaign(camp_id) )
  hash[:active_ad_tags].shuffle!
  hash.store(:test_tag, hash[:active_ad_tags][0] )
  hash.store(:creative_link, tagify(hash[:test_tag]) )
  tag_data = ad_tag_data(hash[:test_tag])
  hash.store(:ad_tag_cpm, tag_data[0])
  hash.store(:network_name, tag_data[1])
  hash.store(:network_id, tag_data[2])
  hash.store(:creative_ids,creatives_by_site_and_camp(hash["siteId"], hash["campaignId"]))
  add_control_perc(hash)
  make_pixel_link(hash)
  pick_affiliate_or_regular(hash)
  test_data << hash
end

conversion_test(test_data, CONVERSIONS)
