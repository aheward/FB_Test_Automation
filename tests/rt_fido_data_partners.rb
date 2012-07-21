#!/usr/bin/env ruby
# coding: UTF-8
=begin

Tests of things in the Data Partners tab.

=end
TEST_TYPE = :rt
require '../config/fido_env'

dp_index = @accounts_index.data_partners

ndp = dp_index.add_data_partner

@dpname = random_alphanums
@dsname = random_alphanums

ndp.data_partner_name=@dpname
ndp.data_source_name=@dsname
ndp.due_to_fetchback="22.2"
ndp.minimum_cpm="12.34"
ndp.check_anonymous_source
ndp.create

element_test(ndp.info, "successfully created")

dp_index = ndp.data_partner_index

list_include(dp_index.data_partner_names, @dpname)

dp = dp_index.open_data_partner @dpname

dp.status="Deleted"
dp.update

element_test(ndp.info, "successfully updated")

dp_index = dp.data_partner_index

list_exclude(dp_index.data_partner_names, @dpname)

@browser.close

