=begin

On PRODUCTION, This script serves a bunch of imps without successing.

Things to do:

=end
#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

test_data = get_landing_test_data(10)

pixel_and_imp_only(test_data)