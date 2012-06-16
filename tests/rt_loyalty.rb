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

regression_conversion_test(test_sites, CONVERSIONS)
