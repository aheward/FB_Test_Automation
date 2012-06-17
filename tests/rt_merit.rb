#!/usr/bin/env ruby
TEST_TYPE = :rt
require '../config/conversion_env'

test_sites = get_merit_test_data(MERIT_OFFSETS.length)

conversion_test(test_sites, %w{vtc})