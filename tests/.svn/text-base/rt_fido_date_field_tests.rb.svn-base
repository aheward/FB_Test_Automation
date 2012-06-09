#!/usr/bin/env ruby
# coding: UTF-8

require '../config/fido_env'

@accounts_index.open_site @fido.test_data['site_2']

# Test modifying date ranges...
@browser.text_field(:id, "dateRange").set("Apr 25, 2011 to Apr 30, 2011")
@browser.button(:value, "Go").click
if @browser.text_field(:id, "dateRange").value == "Apr 25, 2011 to Apr 30, 2011"
  puts ">>>Site Overview date passed"
else
  puts ""
  puts "=============="
  puts "Site Overview date Failed!"
  puts "=============="
  puts ""
end

@browser.link(:text=>"Dashboard", :index=>1).click

@browser.text_field(:id, "dateRange").set("Mar 8, 2011 to Mar 15, 2011")
@browser.button(:value, "Go").click
if @browser.text_field(:id, "dateRange").value == "Mar 8, 2011 to Mar 15, 2011"
  puts ">>>Dashboard date passed"
else
  puts ""
  puts "=============="
  puts "Dashboard date Failed!"
  puts "=============="
  puts ""
end

nav( "Reports")
@browser.checkbox(:id, "prospects").set

@browser.text_field(:id, "dateRange").set("Apr 3, 2011 to Apr 11, 2011")
@browser.button(:value, "Go").click
if @browser.text_field(:id, "dateRange").value == "Apr 3, 2011 to Apr 11, 2011"
  puts ">>>Reports date passed"
else
  puts ""
  puts "=============="
  puts "Reports date Failed!"
  puts "=============="
  puts ""
end

nav("Sites Index")
test("Cash Balance")

nav("N")
test("Name")

nav(@fido.test_data['site_3'])
test("Site Overview: #{@fido.test_data['site_3']}")

nav("Account Home")
test("Account Overview: #{@fido.test_data['test_account']}")

@browser.text_field(:id, "dateRange").value="Apr 12, 2011 to Apr 13, 2011"
@browser.button(:value, "Go").click
if @browser.text_field(:id, "dateRange").value == "Apr 12, 2011 to Apr 13, 2011"
  puts ">>>Account Overview date passed"
else
  puts ""
  puts "=============="
  puts "Account Overview date Failed!"
  puts "=============="
  puts ""
end

@browser.close