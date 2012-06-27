#!/usr/bin/env ruby
# coding: UTF-8
TEST_TYPE = :rt
require '../config/fido_env'

site = @accounts_index.open_site @fido.test_data['site_2']
campaign = site.open_campaign "dynamic"
test("Pixel Implementation Instructions")

campaign.uat_pixels

if @browser.div(:id, "uatNonsecure").visible?
  puts "UAT Link passed"
else
  puts ""
  puts "=============="
  puts "UAT Link Broken!"
  puts "=============="
  puts ""
end

creative_home = campaign.open_creative @fido.test_data['test_creative']

test("Creative Overview: #{@fido.test_data['test_creative']}")

nav("Creative Keywords")
test("To delete all entries, submit an empty input box.")

nav("Creative Home")
test("Creative Assets")
creative = Creative.new @browser
#More time to test file uploads
sleep(5) # TODO: Add file upload code.

flashclickTag = File.open("flash_clicktag.txt").read

creative.showhide_template
creative.template_third_party="3rd Party Tag"
creative.third_party_tag="flash:clickTag"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flashclickTag.chomp
  puts ">>> flash:clickTag test passed."
else
  puts ""
  puts "=============="
  puts "flash:clickTag Test failed!"
  puts "=============="
  puts ""
  puts creative.third_party_tag
  puts
  p flashclickTag
  p creative.third_party_tag
end

flash_clickTAG = File.open("flash_caps_clicktag.txt").read

creative.third_party_tag="flash:clickTAG"
creative = creative.update

if creative.template_fields_element.visible?
  puts ""
  puts "=============="
  puts "Template not hiding on update!"
  puts "=============="
  puts ""
end

creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flash_clickTAG.chomp
  puts ">>> flash:clickTAG test passed."
else
  puts ""
  puts "=============="
  puts "flash:clickTAG Test failed!"
  puts "=============="
  puts ""

end

flashproduct = File.open("flash_product.txt").read

creative.third_party_tag="flash:product"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == flashproduct.chomp
  puts ">>> flash:product test passed."
else
  puts ""
  puts "=============="
  puts "flash:product Test failed if you're testing on qa-fido"
  puts "=============="
  puts creative.third_party_tag
  puts ""

end

default = File.open("default.txt").read

creative.third_party_tag="static:default"
creative = creative.update
creative.showhide_template
creative.template_third_party="3rd Party Tag"

if creative.third_party_tag == default.chomp
  puts ">>> static:default test passed."
else
  puts ""
  puts "=============="
  puts "static:default Test failed!"
  puts "=============="
  puts ""

end

@browser.close