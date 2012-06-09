#!/usr/bin/env ruby
# coding: UTF-8

require '../config/fido_env'


# =============================
# Tests for rejecting Non-ASCII chars...
# =============================

site = @accounts_index.open_site @fido.test_data['site_4_chr_test']

# Existing Account
account = site.account_home_page

check_text_field("TextField_0", "name contains one or more invalid characters.", "successfully updated.")

# TODO Put in check for duplicate names!!!

# Existing Brandings

nav("Add/Edit Brandings")
check_text_field( "branding_name", "name contains one or more invalid characters.", "You must select a logo")

# Existing Site

nav("Account Home")
# First site listed in sites list...
@browser.link(:id, "ExternalLink_5_0").click

# Text fields

check_text_field("siteName", "name contains one or more invalid characters.", "successfully updated.")

@browser.text_field(:id, "trustedDomains").value = random_non_ASCII_string(5, "") + random_ASCII_string(25, "")
submit

if @browser.text_field(:id, "trustedDomains").value.is_ascii?
  puts ">>> Trusted Domains field is only ASCII"
else
  puts ""
  puts "=============="
  puts "The Trusted Domains field allowed non-ASCII chars!"
  puts "=============="
  puts ""
end

check_URL_field("url")
exit
# Number fields
field_ids = [ "CPM",
              "CPA",
              "percentRevenueShare",
              "CPC",
              "targetCPC_ECPM",
              "maxCPCBidPrice",
              "CPE",
              "targetCPE_ECPM",
              "maxCPEBidPrice","maxECPM",
              "goalCPA",
              "goalCPC",
              "baselineReturnConversions",
              "controlGroupeConverstionRate",
              "conversionValue",
              "minimumChargePerPeriod"
]

field_ids.each do | id |

  @browser.text_field(:id, id).value = 0

end

@browser.text_field(:id, "chargePeriod").value = 0
submit

test("Charge Period must be between 1 and 999 days.")

@browser.text_field(:id, "chargePeriod").value = 30
submit

field_ids.each do | id |

  check_num_field(id)
  @browser.text_field(:id, id).value = 0
  submit

end

site = Site.new(@browser).open_site @fido.test_data['site_2_4_chr_test']

# Existing Campaign
campaign = site.open_campaign(site.default_campaign)

check_text_field("adminCampaignName", "one or more invalid characters.", "completed successfully.")

check_num_field("priorityWeight")

# Campaign Keywords
site = campaign.site_home
keyword_matching = site.keyword_matching

keyword_matching.add_multiple_keywords

if keyword_matching.keywords_element.visible?
  puts ">>> Keywords page passed"
else
  puts "==================="
  puts "Keywords page failed"
  puts "==================="
end

site = keyword_matching.site_home
campaign = site.open_campaign(site.default_campaign)

# Existing Creative

@creative = campaign.open_creative(campaign.creative_names[0])

@creative.ordered_sequence=random_ASCII_string(4, "")

test("**")

@creative.ordered_sequence="17.9"

check_num_field("TextField_0")

creative_fields = ["name", "clickUrl", "htmlTemplate", "globalClick","globalLanding", "productClick", "productLanding"]

creative_fields.each do | field |
  @creative.showhide_template
  @creative.showhide_clicktrack

  @browser.text_field(:id, field).value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
  submit

  ascii_test(field)
end

# Existing Network
#network = @creative.open_network @fido.test_data['test_network']

check_text_field("TextField_0", "name contains one or more invalid characters.", "successfully updated.")
check_URL_field("TextField_1")

2.upto(4) do | x |
  next if x == 1

  @browser.text_field(:id, "TextField_#{x}").value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
  submit

  ascii_test("TextField_#{x}")

end

# Existing Ad Tag
nav("Ad Tags Index")
@browser.link(:id, "ExternalLink_9_10").click

@browser.text_field(:id, "TextField_6").value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
submit

test("Account Ids must be numeric, separated by a space.")

@browser.text_field(:id, "TextField_6").value = "2121"

field_ids = ["TextArea", "negativeMatch", "negativeSSLMatch", "TextField_0",
             "positiveMatch", "positiveSSLMatch"]

field_ids.each do | id |
  @browser.text_field(:id, id).value = random_ASCII_string(32, "") + random_non_ASCII_string(32, "")
  submit

  ascii_test(id)
end

[ "1", "2", "4", "5"].each do | x |
  @browser.text_field(:id, "TextField_#{x}").value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
  submit
  puts "TextField_#{x}"
  test("**")

  @browser.text_field(:id, "TextField_#{x}").value = 1
end
submit
test("modified.")

@browser.close
