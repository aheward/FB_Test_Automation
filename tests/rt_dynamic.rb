#!/usr/bin/env ruby
=begin

Tests the DTC, CTC, and VTC conversions for landing campaigns.

=end
TEST_TYPE = :rt
require '../config/conversion_env'

test_data = get_dynamic_test_data(10)

regression_conversion_test(@config, test_data, CONVERSIONS)