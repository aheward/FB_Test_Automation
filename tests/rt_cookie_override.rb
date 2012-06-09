#!/usr/bin/env ruby
require '../config/conversion_env'

@blacklist = BlacklistedSites.new.sites
# Below is the array that will contain hashes of the test data.
# Test data collected and stored in the hashes:
#  "site name", "id", "cookie override", "show popular browsed", "ad tag id", "campaign", "cpm"
data_hashes_array = []

#collect and organize the site data...
4.times do | x |
	
	x < 2 ? co = 0 : co = 1
	x == 0 || x == 2 ? spb = 0 : spb = 1

	sites = $sites_db.get_cukov_by_co_and_spb(co, spb)

	sites.delete_if { | row | row["name"] =~ /opt.*out/i }
	sites.delete_if { | row | row["name"] =~ /UK/ }

	sites.shuffle!

	data_hashes_array << sites[0..10]

end

data_hashes_array.flatten!
data_hashes_array.delete_if { |item| @blacklist.include?(item["siteId"]) }

# Clean up the hash, and add the campaign and ad tag information...
data_hashes_array.each do | hash |
	
	0.upto(3) do | x |
		hash.delete(x)
	end

	campaigns = $sites_db.get_camp_names_by_sid(hash['siteId'])

	campaigns.delete_if do | chash |
		
		chash["name"] != "dynamic" && chash["name"] !="landing" 
		
	end	
	
	if campaigns == []
		
		hash.clear
		next
		
	end

	# Here's where we need logic for the situation where there's both dynamic and landing campaigns
	# and show popular browsed is NOT selected....

	if campaigns.include?({"name"=>"landing", 0=>"landing"}) && campaigns.include?({"name"=>"dynamic", 0=>"dynamic"}) && hash["showPopularBrowsed"] == 0 && hash["cookieOverride"] == 1
		hash["campaign"] = "landing"
	else
		hash["campaign"] = campaigns[0]["name"]
	end

	camp_id = $sites_db.get_cpid_from_sid_and_cpname(hash['siteId'], hash['campaign'])

	ad_tags = $sites_db.get_ad_tags_by_site_and_camp(hash["siteId"], camp_id)

	begin
		ad_tags.flatten!.shuffle!
	rescue NoMethodError
		hash.clear
		next
	end

	hash["ad_tag"] = ad_tags[0]

	cpm_raw = $sites_db.get_network_cpm(hash["ad_tag"], true)
	hash["cpm"] = cpm_raw[0]["cpm"]

end

# Get rid of empty entries...
data_hashes_array.delete_if { | x | x == {} }

# Figure out the expected Imp code...
data_hashes_array.each { | hash | hash.calc_imp_code }

data_hashes_array.shuffle!

def serve_imps(hash_array, return_code)
	
	hash_array.each do | hash |
		
		hash['imp_code'] == 4 ? rc = 4005 : rc = return_code
    string =  "| #{hash['name']} | ID: #{hash['siteId']} | #{hash['campaign']} |"
    border = "+"
    (string.length-2).times { border << "="}
    border << "+"
    puts border
    puts string
    puts border
    puts
		puts "Cookie Override: #{hash['cookieOverride']==1 ? "Yes" : "No"}"
		puts "Show Popular Browsed: #{hash['showPopularBrowsed']==1 ? "Yes" : "No"}"

		if return_code == 1007
			puts "No Cookie History"
		else
			puts "Other Site Cookies"
		end		
		puts "IMP Link: #{tagify(hash['ad_tag'])}"
		puts "Expected Return Code: #{rc}"
		
		sleep(1)
		imp_cutoff = calc_offset_time(@config.offset, 1)
		#puts imp_cutoff
		@browser.goto(tagify(hash["ad_tag"]))
		sleep(1)
		
		imp_array = filtrate(get_log(@config.imp_log), imp_cutoff)
		#p imp_array
		imp_array.keep_if { | lines | lines.include?("\timp\t") }
		imp_hash = split_log(imp_array[-1], "impression")
		puts "Actual Return Code: #{imp_hash[:return_code]}"
		puts ""
		puts "Imp log entry:"
		puts imp_array[-1]

		if hash['campaign'] == "dynamic"
			
			proxy_log = get_log(@config.proxy_log)

			puts ""
			puts "Proxy log:"
			puts proxy_filtrate(proxy_log, imp_cutoff, hash['id'])
			
		end
		
		puts "Log entry has unexpected tag id. Something's up." if hash['ad_tag'] != imp_hash[:adtag_id]
		
		if imp_hash[:return_code] == rc.to_s
			puts "PASSED"
		elsif imp_hash[:return_code] == "2002" # "2002" is the return code when Ad Tag Preview is in effect
			puts "Ad Tag Preview mode"
		elsif imp_hash[:creative_id] == "64" # Sometimes the test site has an active skyscraper ad tag, but the creative is not
			puts "Unclean AdTag?"
		else	
			puts "FAILED"
		end	
		
		puts ""
		
	end

end

@browser = @config.browser

puts "+=========================+"
puts "|  Cookie Override Tests  |"
puts "+=========================+"
puts ""
puts "Number of sites tested: #{data_hashes_array.length}"
# No history
puts ""

serve_imps(data_hashes_array, 1007)

# Other site cookie history
# So, we want to make sure there's a history in the cookies.
# Here we pick a random client site to go to and get pixeled...

puts ""

# This list is needed in case the first (or second) site visited doesn't fire the pixel properly...
random_site = ["http://harrison.edu/", 
"http://www.gnc.com/product/index.jsp?productId=3509954&cp=4046468.4174422",
"http://www.shutterstock.com/subscribe.mhtml", 
"http://www.1800dentist.com",
"http://www.zulily.com",
"http://www.zurchers.com",
"http://www.123print.com/Wedding",
"http://www.999inks.com",
"http://www.511tactical.com/All-Products/Flashlights/Light-For-Life-Flashlight-PC3300.html",
"http://www.accessorygeeks.com/ichair-iphone-4-rubber-case-kickstand-screen-blk-blue.html",
"http://www.aboutairportparking.com/newark-liberty-international-airport-parking"]
	
cuhkies = 0
until cuhkies == 1 do

	@browser.goto(random_site[rand(random_site.length)])
	sleep(1)
	@browser.goto("http://#{@config.test_site}/fido/")
  login = LoginPage.new @browser
  accounts_index = login.fido_log_in(@config.fido_username, @config.fido_password)
	misc = accounts_index.misc_tab
  cookie_analysis = misc.cookie_analysis

	if cookie_analysis.campaign_history_element.text.include?("No campaign cookie history is available.")
		cuhkies = 0 
	else
		cuhkies = 1
	end	
	
end

serve_imps(data_hashes_array, 1010)

