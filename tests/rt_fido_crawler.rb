#!/usr/bin/env ruby
# coding: UTF-8
=begin

Simple crawler of Fido to ensure no pages are grossly dysfunctional.

=end
TEST_TYPE = :rt
require '../config/fido_env'

nav("My Account")
test("Personal Information")

nav("Networks")
test("DoubleVerify")

nav("Users")
test("Jiwa")

nav("Misc")
test("Look to the left!")
misc_page = Misc.new @browser

puts "Fido version number: " + misc_page.project_version
test(@fido.test_data['fido_version'])

nav("Account Home")
test("Cash Balance")

nav("Sites Index")
test("Aboutairportparking")

nav("Z")
test(@fido.test_data['site_2'])

nav(@fido.test_data['site_2'])
test("Site Overview: #{@fido.test_data['site_2']}")

zagg = Site.new(@browser)

zagg.showhide_affiliate_links
puts "-------SITE------"
puts "Name: #{zagg.name}"
puts "ID: #{zagg.id}"
puts "URL: #{zagg.url}"
puts "Specialist:#{zagg.specialist}"
puts "AM: #{zagg.am}"
puts "Cookie Override: #{zagg.cookie_override_checked?}"
puts "Dynamic Campaign Weighting: #{zagg.dynamic_campaign_weighting_checked?}"
puts "Use Best Weighted Campaign: #{zagg.use_best_weighted_checked?}"
puts "Trusted Domains Enabled: #{zagg.trusted_domains_enabled_checked?}"
puts "Trusted Domains: #{zagg.trusted_domains}"
puts "Status: #{zagg.status}"
puts "CPM: #{zagg.cpm}"
puts "Goal CPA: #{zagg.goal_cpa}"
puts "Charge Period Start: #{zagg.charge_period_start}"
puts "Pepperjam URL: #{zagg.pepperjam_url_1}"
puts "Default Campaign: #{zagg.default_campaign}"
puts "Impressions: #{zagg.impression_count}"
puts "--------------"

nav("Campaigns")

#charge period character limitation test...
zagg.charge_period="999"
submit

if zagg.charge_period == "999"
	
	puts ">>> Charge Period passed."
	
else 
	puts ""
	puts "=============="
	puts "Charge Period Broken!"
	puts zagg.charge_period
	puts "=============="
	puts ""
end

# Add a campaign...

nav( "Add Campaign")
campaign_name = random_alphanums(64)
@browser.text_field(:id, "adminCampaignName").value=campaign_name
@browser.select(:id, "status").select("Active")
submit

#did it get created?
test("successfully created.")

#=begin
#go to the campaign...
nav("Site Home")

nav(zagg.default_campaign)

badges_csv = %|\"\",\"\",\"logo\",\"logo\",\"\"\n\"\",\"\",\"bg\",\"bg\",\"\"\n\"\",\"\",\"fg\",\"fg\",\"\"\n\"\",\"\",\"msg\",\"msg\",\"\"\n\"\",\"\",\"prefix\",\"prefix\",\"\"\n\"\",\"\",\"badgeFindLocation\",\"foo\",\"\"\n\"\",\"\",\"badgeFindLocationButtonCSS\",\"border:1; width:40px; height:23px;position:absolute;bottom:0px;left:0px;z-index:9998;\",\"\"\n\"\",\"\",\"badgeFindLocationInputCSS\",\"border:1; width:70px; height:23px;position:absolute;bottom:0px;left:40px;z-index:9998;\",\"\"\n\"\",\"\",\"badgeFacebookLikeUrl\",\"http://www.woodyafterhours.com\",\"\"\n\"\",\"\",\"badgeFacebookLikeCSS\",\"background:#FF00FF; border:0; width:23px; height:23px; position:absolute ;bottom:23px; left:23px; z-index:9998;\",\"\"\n\"\",\"\",\"badgeFacebookFanpageUrl\",\"http://www.woodyafterhours.com\",\"\"\n\"\",\"\",\"badgeFacebookFanpageCSS\",\"position:absolute;width:23px;height:23px;left:0px;bottom:45px;background:#FF00FF url('/serve/images/facebook.png');\",\"\"\n\"\",\"\",\"badgeTwitterFanpageUrl\",\"http://www.woodyafterhours.com\",\"\"\n\"\",\"\",\"badgeTwitterFanpageCSS\",\"position:absolute;width:23px;height:23px;left:0px;bottom:0px;background: url('/serve/images/twitter.png');\",\"\"\n|

#fill out Worksheet...
badges_tab =<<goof
		logo	logo	
		bg	bg	
		fg	fg	
		msg	msg	
		prefix	prefix	
		badgeFindLocation	foo	
		badgeFindLocationButtonCSS	border:1; width:40px; height:23px;position:absolute;bottom:0px;left:0px;z-index:9998;	
		badgeFindLocationInputCSS	border:1; width:70px; height:23px;position:absolute;bottom:0px;left:40px;z-index:9998;	
		badgeFacebookLikeUrl	http://www.woodyafterhours.com	
		badgeFacebookLikeCSS	background:#FF00FF; border:0; width:23px; height:23px; position:absolute ;bottom:23px; left:23px; z-index:9998;	
		badgeFacebookFanpageUrl	http://www.woodyafterhours.com	
		badgeFacebookFanpageCSS	position:absolute;width:23px;height:23px;left:0px;bottom:45px;background:#FF00FF url('/serve/images/facebook.png');	
		badgeTwitterFanpageUrl	http://www.woodyafterhours.com	
		badgeTwitterFanpageCSS	position:absolute;width:23px;height:23px;left:0px;bottom:0px;background: url('/serve/images/twitter.png');	
goof

@browser.select(:id, "variableWorkspaceMode").select("CSV Format")

@browser.text_field(:id, "textareaCSV").value=badges_csv

@browser.select(:id, "variableWorkspaceMode").select("Table Format")
# NOTE:
# This line MUST NOT USE the defined submit method!!!!
# It NEEDS to click on the DAM-IT update button specifically.
@browser.button(:id, "Submit_0").click

@browser.select(:id, "variableWorkspaceMode").select("Tab Format (For Cut and Paste To/From Excel)")

if @browser.text_field(:id, "textareaTAB").value == badges_tab
	puts ">>> DAM-IT Worksheet passed"
else
	puts ""
	puts "=============="
	puts "Test of DAM-IT Worksheet failed!"
	puts "=============="
	puts ""
end	

nav("Site Home")
nav(campaign_name)

# then add creatives...
nav("Add Creative")
creative = random_alphanums(64)

foo = Creative.new(@browser)

foo.ordered_sequence="1.0"
foo.creative_name=creative
foo.type="Pop"
foo = foo.create

test("Creative properties sucessfully modified.")

nav("Multiple Assets")

#here is time to test the uploading of files...
sleep(5)  # TODO: Add code for uploading files. Needs config for files directory.

#@browser.button(:value, "Upload Assets").click

nav("Campaign Home")
campaign = Campaign.new @browser
test(@fido.test_data['test_network'])

if campaign.ssl_href == "https://qa-pixel.fetchback.com/serve/fb/pdj?cat=&name=#{campaign_name}&sid=#{@fido.test_data['site_id_4_ssl']}"
	puts ">>> SSL Pixel link passed"
else
	puts ""
	puts "=============="
	puts "SSL Pixel link failed if you're testing on qa-fido!"
  puts campaign.ssl_href
	puts "=============="
	puts ""
end

if campaign.non_ssl_href == "http://qa-pixel.fetchback.com/serve/fb/pdj?cat=&name=#{campaign_name}&sid=#{@fido.test_data['site_id_4_ssl']}"
	puts ">>> Non-SSL Pixel link passed"
else
	puts ""
	puts "=============="
	puts "Non-SSL Pixel link failed if you're testing on qa-fido!"
	puts "=============="
	puts ""
end

puts "-------CAMPAIGN-------"
puts "Campaign Name: #{campaign.campaign_name}"
puts "ID: #{campaign.id}"
puts "Creative plus PDC: #{campaign.creative_plus_pdc_checked?}"
puts "Creatives: #{campaign.creative_names}"
puts "Ad Tags: #{campaign.network_adtag_names}"
puts "--------------"

dbck = campaign.open_ad_tag(@fido.test_data['test_ad_tag_name'])

test("SSL Pixel Tag")

puts "------ADTAG--------"
puts "ID: #{dbck.id}"
puts "Network: #{dbck.network}"
puts "Name: #{dbck.name}"
puts "Status: #{dbck.status}"
puts "Associated Accounts: #{dbck.associated_account}"
puts "Pixel Tag: #{dbck.pixel_tag}"
puts "Medium Rectangle ID: #{dbck.mrect_id}"
puts "ad tag ids: #{dbck.ids}"
puts "--------------"

nav("Terms & Conditions")
test("FetchBack will refund any amounts remaining on deposit")

nav("Privacy Policy")
test("FetchBack takes the security of your information seriously, and we take measures to protect our data from unauthorized access, as well as unauthorized disclosure or destruction of data. Our data center provides the highest quality security for your data. Security, fire, and life-safety systems were designed and operate to support the important objective of data preservation. Advanced technologies such as digital video, electronic access control, biometric security, VESDA and pre-action fire suppression are used throughout. FetchBack is committed to securing the data of our Advertisers and their Prospects.")

nav("Misc")
test("Look to the left!")

nav("Cookie Analysis")
test("No keyword cookie history is available.")

# Goal Setting tests...
nav("Goal Setting")
test("Select Account Manager")

goal_setting = GoalSetting.new @browser

goal_setting.select_account_manager=@fido.test_data['account_manager']
goal_setting.show_report

if @browser.select(:id, "PropertySelection_2").selected_options[0].text == @fido.test_data['account_manager']
	puts ">>> Goal Setting AM passed"
else
	puts ""
	puts "=============="
	puts "Goal Setting Broken!"
	p @browser.select(:id, "PropertySelection_2").selected_options[0].text
	puts "=============="
	puts ""
end

nav("Accounts Index")

test("Credit Enabled")

# Create Account....

nav("Add Account")
test("Account Creation")

account = random_alphanums(64)

@browser.text_field(:id, "TextField_0").value=account

@browser.select(:id, "PropertySelection").select("Tony Salyer")
@browser.select(:id, "PropertySelection_0").select("Active")

submit

test("successfully") 

@browser.select(:id, "PropertySelection_0").select("Active")
submit

test("Account must have positive cash balance or be credit-enabled prior to ACTIVE status. See the Accounting Team.")

nav("Accounts Index")
index = AccountsIndex.new @browser

account = index.open_account @fido.test_data['test_account_2']
puts "------ACCOUNT--------"
puts account.name
puts account.id
puts account.current_balance
puts account.status
puts account.am
puts account.site_ids  # TODO: These are broken. Fix/Improve/Remove for phase 2
puts account.site_names
puts account.site_statuses
puts account.site_investments
puts "--------------"

nav("I/O Accountability")
test("Create I/O")

nav("Accounts Index")
test(@fido.test_data['test_account_2'])

nav(@fido.test_data['test_account_2'])
test("Account Overview: #{@fido.test_data['test_account_2']}")

nav("Networks")
test("URL")

nav("Add Network Tag")
test("Success SSL Pixel Tag")

ad_tag_name = random_alphanums(64)

#test the UAT pixel switchover...

@browser.checkbox(:id, "urlOnly").set

if @browser.text_field(:id, "negativeUrl").visible? == true
	puts ">>> UAT Pixel Fields Pass"
else
	puts ""
	puts "=============="
	puts "UAT Pixel Fields failed!"
	puts "=============="
	puts ""
end

@browser.checkbox(:id, "urlOnly").clear 

if @browser.text_field(:id, "negativeUrl").visible? == false
	puts ">>> Regular Pixel boxes Pass"
else
	puts ""
	puts "=============="
	puts "Regular Pixel fields failed!"
	puts "=============="
	puts ""
end

#test the error checkers...
@browser.text_field(:id, "TextField_0").value=ad_tag_name

@browser.select(:id, "PropertySelection").select("testing-only")
@browser.checkbox(:id, "Checkbox").set
@browser.checkbox(:id, "Checkbox_0_0").set
@browser.checkbox(:id, "Checkbox_0_2").set
@browser.checkbox(:id, "Checkbox_0_5").set
@browser.checkbox(:id, "Checkbox_0_6").set
@browser.checkbox(:id, "Checkbox_0_7").set
@browser.checkbox(:id, "Checkbox_0_8").set
@browser.checkbox(:id, "Checkbox_0_9").set
@browser.checkbox(:id, "Checkbox_0_10").set
@browser.checkbox(:id, "Checkbox_0_11").set
@browser.checkbox(:id, "Checkbox_0_12").set
@browser.checkbox(:id, "Checkbox_0_13").set
@browser.checkbox(:id, "Checkbox_0_14").set
@browser.checkbox(:id, "Checkbox_0_15").set
@browser.checkbox(:id, "Checkbox_0_16").set
@browser.checkbox(:id, "Checkbox_0_17").set
@browser.checkbox(:id, "Checkbox_0_18").set

@browser.text_field(:id, "TextField_3").set("1/12")
@browser.text_field(:id, "TextField_6").set("1464")
@browser.checkbox(:id, "Checkbox_1").clear
submit

test("Required Standard Pixel Tag was not specified.")

@browser.text_field(:id, "TextField_6").set("9999999")
tag = <<goof
<img src='http://www.google.com/intl/en_ALL/images/logo.gif' border='0'  width='1px' height='1px' />
goof
@browser.text_field(:id, "negativeMatch").value=tag
submit

test("Error: One or more specified accounts does not exist.")

# Adds the ad tag to "Zagg"
@browser.text_field(:id, "TextField_6").set(@fido.test_data['account_id'])
submit

test("successfully created.")

# test presence/absence of flat fee field on campaign page...

site = Site.new(@browser).open_site(@fido.test_data['flat_fee_site'])

if site.flat_fee_checked?
	campaign = site.open_campaign "landing"
else
	@browser.checkbox(:name, "flatFee").set    # TODO: convert all these to phase 2 versions.
	@browser.text_field(:id, "CPE").value="0"
	@browser.text_field(:id, "maxCPCBidPrice").value="0"
	@browser.text_field(:id, "CPA").value="0"
	@browser.text_field(:id, "goalCPC").value="0"
	@browser.text_field(:id, "goalCPA").value="0"
	@browser.text_field(:id, "targetCPC_ECPM").value="0"
	@browser.text_field(:id, "targetCPE_ECPM").value="0"
	@browser.text_field(:id, "CPC").value="0"
	@browser.text_field(:id, "maxCPCBidPrice").value="0"
	@browser.text_field(:id, "maxCPEBidPrice").value="0"
	submit
  campaign = site.open_campaign "landing"
end

if @browser.link(:text, "Campaign Pricing").exist?
	puts ">>>Flat Fee field test 1 passed"
else
	puts ""
	puts "=============="
	puts "Flat Fee field test 1 failed!"
	puts "=============="
	puts ""
end 

site = campaign.site_home

site.uncheck_flat_fee
site = site.submit

campaign = site.open_campaign "landing"

if @browser.link(:text, "Campaign Pricing").exist?
	puts ""
	puts "=============="
	puts "Flat Fee field test 2 failed!"
	puts "=============="
	puts ""
else
	puts ">>>Flat Fee field test 2 passed"
end 

site = campaign.open_site @fido.test_data['site_2']

# Test the PUP List stuff...
site.check_pup_list
site = site.submit

if site.completion_percentage_element.visible?
  puts ">>> PUP List passed"
else
  puts ""
  puts "=============="
  puts "Pup list element failed!"
  puts "=============="
  puts ""
end

pup_list = site.pup_list

if pup_list.received_creative_assets?
  puts ">>> PUP List PAGE passed"
else
  puts ""
  puts "=============="
  puts "Pup list PAGE failed!"
  puts "=============="
  puts ""
end

site = pup_list.site_home

io_accountability_page = site.io_accountability

if io_accountability_page.io_amount?
  puts "I/O Accountability Page passed"
else
  puts ""
  puts "=============="
  puts "I/O Accountability page failed!"
  puts "=============="
  puts ""
end

# This sleep is here because otherwise the script is too fast for the Fido UI...
sleep 3

site = io_accountability_page.open_site @fido.test_data['site_2']

campaign = site.open_campaign "landing"

# Have to test that the ad tag got added to the page...
if @browser.text.include?("#{ad_tag_name}")
	puts ">>>Network ad tag addition passed"
else
	puts ""
	puts "=============="
	puts "Regular Pixel fields failed!"
	puts "=============="
	puts ""
end

nav("Users")
test(@fido.test_data['active_user'])

nav("Create User")

user = User.new @browser

user.username="doofus"
user.first_name="doofus"
user.last_name="poofus"
user.email="goo@soo.com"
user.phone="8087436985"
user.check_is_enabled
user.check_is_employee
user.check_is_admin

password = random_alphanums_plus(4) 
user.password=password
user.create

test("Password not changed or set")

nav("Account Home")
test("Accounts")

nav("Allergy Be Gone")
test("Client Branding")

nav("I/O Accountability")
test("Create I/O")

nav("Account Home")
test("Auto-Renew I/O")

nav("Add/Edit Brandings")
test("System Brandings")

branding = random_alphanums(6)

@browser.text_field(:id, "branding_name").set(branding)
@browser.button(:value, "Submit").click

test("You must select a logo")

nav("Networks")
nav("Add Network")

network = random_alphanums(64)
username = random_alphanums(16)
password = random_alphanums(8)
@browser.select(:id, "PropertySelection").select("Active")
@browser.text_field(:id, "TextField_1").value="http://www.funkytowne.com"
@browser.text_field(:id, "TextField_2").value=username
@browser.text_field(:id, "TextField_3").value=password
@browser.text_field(:id, "TextField_4").value="doof@poof.com"
@browser.text_field(:id, "TextField_0").value=network

submit

test("successfully created.")

# Commit Sort Test...
site = Site.new(@browser).open_site @fido.test_data['uat_site_name']
campaign = site.open_campaign "landing"
nav("Commit Sort")
sleep(2)
test("Info: Commit was completed successfully.")

site = campaign.site_home

# Blank Specialist Field test...
site.specialist=""
site = site.submit
test("FetchBack Specialist is a required field.")

@browser.close