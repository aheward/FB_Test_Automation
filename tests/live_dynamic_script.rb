=begin

On PRODUCTION, This script serves a bunch of imps without successing.

Things to do:
- fix the pixel log = nil garbage. That's not working right.

=end
#!/usr/bin/env ruby
TEST_TYPE = :prod
require '../config/conversion_env'

test_data = get_dynamic_test_data(10)

pixel_and_imp_only(test_data)
