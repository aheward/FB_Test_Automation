=begin

Tests the Loyalty Campaign on Production

Things to do:
- Still need to add a click of the loyalty imp and then 
a success after that, so as to test the remittance
value.

=end

#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

test_data = data_for_a_campaign("landing", "Site-A")
set_up_one_site(test_data[0])
test_data[0][:loyalty_id] = cpid_from_sid_and_cpname(test_data[0]['siteId'], "loyalty.campaign")

%w{vtc ctc}.each do |loyalty_conversion_test|
  test_data[0][:loyalty_conv_type] = loyalty_conversion_test
  conversion_test(test_data, CONVERSIONS)
end
