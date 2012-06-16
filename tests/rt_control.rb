#!/usr/bin/env ruby
=begin

Tests the Control Campaign on the test sites.

=end
TEST_TYPE = :rt
require '../config/conversion_env'

test_sites = get_control_test_data(10)

regression_conversion_test(test_sites, %w{vtc})
