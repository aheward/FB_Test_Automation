#!/usr/bin/env ruby
# coding: UTF-8
TEST_TYPE = :rt
require '../config/fido_env'

# Test Overview Numbers...
site = @accounts_index.open_site @fido.test_data['site_1']

imp_count = []

site.campaign_impressions.values.each do | string |

  if string == "n/a"
    imp_count << 0
  else
    string.gsub!(",", "")
    string = string.to_i
    imp_count << string
  end

end

int_imp_count = site.impression_count.gsub!(",", "").to_i

if imp_count.inject(:+) == int_imp_count
  puts ">>>Imp counts passed"
else
  puts ""
  puts "=============="
  puts "Campaign/Site Imp Counts aren't equal!"
  puts "#{imp_count.inject(:+)} versus #{int_imp_count}"
  puts "=============="
  puts ""
end

site_ic = site.incremental_conversions.gsub(/[$ ,]/, "").to_f
site_investment = site.investment.gsub(/[$ ,]/, "").to_f
site_cpa = site.overview_cpa.gsub(/[$ ,]/, "").to_f

if (site_investment / site_ic).equals?(site_cpa)
  puts ">>>Site CPA calculation passed"
else
  puts ""
  puts "=============="
  puts "Site CPA calculation does not look right!"
  puts "#{site_investment / site_ic} versus #{site_cpa}"
  puts "=============="
  puts ""
end

@browser.close