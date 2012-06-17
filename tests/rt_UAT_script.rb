#!/usr/bin/env ruby
TEST_TYPE = :rt
require '../config/conversion_env'

test_data = get_uat_test_data

conversion_test(test_data, %w{vtc ctc})
