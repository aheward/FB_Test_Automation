#!/usr/bin/env ruby
# Modify this variable to select
# the site you want to test...
# Obviously the name must match EXACTLY...
test_site = "angieslist.com"

# =================
TEST_TYPE = :rt
require '../config/conversion_env'

site = SITES_DB.cukov_data_by_site_name(test_site)

test_hash = site[0]

campaigns = SITES_DB.camp_names_by_sid(test_hash['siteId'])

campaigns.delete_if do | chash |
	
	chash["name"] != "dynamic" && chash["name"] != "landing"
	
end	
	
if campaigns == []
	FBErrorMessages::Sites.no_campaigns
  exit
end

cookie_override_header(test_site, test_hash['cookieOverride'], test_hash['showPopularBrowsed'])

# Campaigns logic...
if campaigns.include?({"name"=>"landing", 0=>"landing"})
	puts "Site has a landing campaign"
	test_hash[:landing] = 1
else
	puts "No Landing"
	test_hash[:landing] = 0
end

if campaigns.include?({"name"=>"dynamic", 0=>"dynamic"})
	puts "Site has a dynamic campaign"
	test_hash[:dynamic] = 1
else
	puts "No dynamic"
	test_hash[:dynamic] = 0
end

# Get ad tag ids...
# Probably going to want to modify this to exclude some of the ad tags.
# We'll see...
ad_tags = SITES_DB.ad_tag_ids_by_site_id(test_hash['siteId'])

begin
	ad_tags.flatten!.shuffle!
rescue NoMethodError
	FBErrorMessages::Imps.no_active_tags
	exit
end	

if ad_tags.length > 15
	
	ad_tags = ad_tags[0..14]

end	

def serve_imps(ad_tags, browser)
	
	ad_tags.each do | ad_tag |

		imp_cutoff = calc_offset_time(2)
		browser.goto(tagify(ad_tag))
    sleep $imp_seconds
    browser.goto DUMMY_PAGE
    $unique_id = browser.unique_identifier

		imp_array = filtrate(get_log($imp_log), imp_cutoff)
		imp_array.keep_if { | lines | lines.include?("\timp\t") }
		imp_hash = split_log(imp_array[-1], "impression")
		#puts "Test for no cookies at all..."
		puts "\nImp log entry:"
		puts imp_array[-1]
		puts "Logged Return Code: #{imp_hash[:return_code]}"
		puts return_code(imp_hash[:return_code])
    browser.show_cookies
	end
	
end	

puts "\nNo cookie history..."
puts "===================="

#Serve test impressions...
serve_imps(ad_tags, @browser)

puts "\nCookie history..."
puts "===================="

# Get pixeled for a random site...
while @browser.sit[:value] =~ /^\d_\d+$/

	@browser.dirty(test_hash['siteId'], 1, 1)
  @browser.goto DUMMY_PAGE

end

#Serve test impressions...

serve_imps(ad_tags, @browser)