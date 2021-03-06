=begin

Simple crawler of Fido to ensure no pages are grossly disfunctional.

Things to do:
- add in password checks once the ugly current FIDO password code is improved
- Refactor to reduce the redundant code and improve the tests being run
- There may be one or two pages missing from the crawl. Not sure. Need to look.
- Though it will slow things down tremendously, the script should probably create 
class instances on every page and verify all variables are present and as 
expected (It may be best to use RSpec and/or Test/Unit for this), for all user
types!
- The above will almost certainly require re-working the class definitions.

=end

#!/usr/bin/env ruby
require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/fido-classes'
include Randomizers
include FidoTamers

@config = FBConfig.new(:prod)

def test(text)
	puts "~~PAGE~~ #{$ff.title}"
	if $ff.text.include?(text)
		puts ">>> Test of '#{text}' passed."
	else
		puts ""
		puts "=============="
		puts "Test of '#{text}' failed!"
		puts "=============="
		puts ""
	end
end

$ff = @config.browser
$ff.goto("https://fido.fetchback.com/serve/login.jsp")

fido_log_in($ff, $username, $password)

$ff.link(:text, "My Account").click
test("Personal Information")

$ff.link(:text, "Networks").click
test("Networks")

$ff.link(:text, "Users").click
test("Users")

$ff.link(:text, "Misc").click
test("Look to the left!")

$ff.link(:text, "Account Home").click
test("Accounts")

$ff.link(:text, "Sites Index").click
test("A-2-Z AHndy Man Network")

$ff.link(:text, "Z").click
test("ZenMed")

$ff.link(:text, "ZenMed").click
test("Site Overview: ZenMed")

$ff.link(:text, "dynamic").click
test("Pixel Implementation Instructions")

$ff.link(:text, "fb_zenmed_728").click
test("Creative Overview: fb_zenmed_728")

$ff.link(:text, "Creative Keywords").click
test("Preview Product Creatives")

$ff.link(:text, "Creative Home").click
test("Creative Assets")

$ff.link(:text, "Campaign Home").click
test("Adtegrity")

$ff.link(:text, "DBCK_ZenMed").click

$ff.window(:title, "FetchBack Campaign").close
$ff.window(:title, "FetchBack NetworkAdTag").use

test("SSL Pixel Tag")

$ff.link(:text, "Ad Tags Index").click
test("Network Ad Tags")

$ff.link(:text, "Terms & Conditions").click
test("FetchBack will refund any amounts remaining on deposit")

$ff.link(:text, "Privacy Policy").click
test("FetchBack takes the security of your information seriously, and we take measures to protect our data from unauthorized access, as well as unauthorized disclosure or destruction of data. Our data center provides the highest quality security for your data. Security, fire, and life-safety systems were designed and operate to support the important objective of data preservation. Advanced technologies such as digital video, electronic access control, biometric security, VESDA and pre-action fire suppression are used throughout. FetchBack is committed to securing the data of our Advertisers and their Prospects.")

$ff.link(:text, "Misc").click
test("Look to the left!")

$ff.link(:text, "Cookie Analysis").click
test("Campaign History")

$ff.link(:text, "Goal Setting").click
test("Select Account Manager")

$ff.link(:text, "Accounts Index").click
test("Credit Enabled")

$ff.link(:text, "Add Account").click
test("Account Creation")

$ff.link(:text, "Sites Index").click
test("Cash Balance")

$ff.link(:text, "N").click
test("Name")

$ff.link(:text, "NFL").click
test("Site Overview: NFL")

$ff.link(:text, "Add Campaign").click
test("Campaign Creation")

$ff.link(:text, "Account Home").click
test("Account Overview: True Action")

$ff.link(:text, "Accounts Index").click
test("Allergy Be Gone")

$ff.link(:text, "Allergy Be Gone").click
test("Account Overview: Allergy Be Gone")

$ff.link(:text, "Add Site").click
test("Site Creation")

$ff.link(:text, "Networks").click
test("Email Address")

$ff.link(:text, "Add Network Tag").click
test("Success SSL Pixel Tag")

$ff.link(:text, "Ad Tags Index").click
test("Network Ad Tags")

$ff.link(:text, "Networks Index").click
test("Email")

$ff.link(:text, "Add Network").click
test("Network Creation")

$ff.link(:text, "Networks Index").click
test("UserName")

$ff.link(:text, "Users").click
test("Telephone")

$ff.link(:text, "Create User").click
test("Last Name")

$ff.text_field(:id, "TextField_0").set("doofus")
$ff.text_field(:id, "TextField_1").set("doofus")
$ff.text_field(:id, "TextField_2").set("poofus")
$ff.text_field(:id, "TextField_3").set("goo@soo.com")
$ff.text_field(:id, "TextField_4").set("8087436985")
$ff.checkbox(:id, "Checkbox").set
$ff.checkbox(:id, "Checkbox_0").set
$ff.checkbox(:id, "Checkbox_1").set
password = random_alphanums_plus(4) 
$ff.text_field(:id, "password").set(password)
$ff.button(:value,"Create").click
test("Password not changed or set.")

$ff.link(:text, "Account Home").click
test("Accounts")

$ff.link(:text, "About Airport Parking").click
test("Client Branding")

$ff.link(:text, "Add/Edit Brandings").click
test("System Brandings")

open_fido_site($ff, "Viva Elvis")
$ff.link(:text, "landing").click
$ff.link(:text, "Commit Sort").click
sleep(2)
test("Info: Commit was completed successfully.")

$ff.link(:text, "Sites Index").click

('A'..'Z').each do |letter|
	puts "Site: #{letter}"
	$ff.link(:text, letter).click
	test("Specialist")
end

$ff.link(:text, "Account Home").click

('A'..'Z').each do |letter|
	puts "Account: #{letter}"
	$ff.link(:text, letter).click
	test("Credit Enabled")
end

$ff.link(:text, "Networks").click

('A'..'Z').each do |letter|
	puts "Network: #{letter}"
	$ff.link(:text, letter).click
	test("UserName")
end

$ff.link(:text, "Log Out").click
test("User:")