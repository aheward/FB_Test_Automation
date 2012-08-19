=begin

Tests Merit values at specified cookie offsets.

Things to do:
- This will need updating when Nikolas finally gets around to making the
cookie page
- At some point it will need to be refactored with RSpec and Test/Unit stuff

=end

#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

test_data = data_for_a_campaign("landing", "Site-A")
set_up_one_site(test_data[0])

test_data.each do |site|
  site_merit_values(site)
end

(MERIT_OFFSETS.length - 1).times { test_data << test_data[0] }

conversion_test(test_data, %w{vtc})
