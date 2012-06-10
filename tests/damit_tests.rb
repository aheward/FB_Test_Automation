#!/usr/bin/env ruby
require '../config/env'
require '../lib/pixel_imp_conversions'

include FidoTamers

@config = FBConfig.new(:rt)

site_data = @config.sites_db
site_data.results_as_hash = true

$ff = @config.browser

sites_and_campaigns = []

site_data.execute( %|SELECT siteId, name FROM campaign_data WHERE name IS NOT "success";|) do |row|
	
	sites_and_campaigns << row
	
end

sites_and_campaigns.shuffle!

$ff.goto("https://#{$test_site}/fido/login.jsp")
fido_log_in($ff, $username, $password)

twitter_url = "http://www.twitter.com"

sites_and_campaigns.each do | hash |
	
	next if hash['name'] == "control"

	findlocationbutton_border = rand(3)
	findlocationbutton_width = rand(60)+20
	findlocationbutton_height = rand(10)+20
	findlocationbutton_position = "absolute" # valid values: absolute, fixed, relative, static, inherit
	findlocationbutton_bottom = rand(30)
	findlocationbutton_left = rand(95)
	findlocationbutton_zindex = rand(5)+9994

	findlocationinput_border = rand(3)
	findlocationinput_width = rand(30)+30
	findlocationinput_position = "absolute"
	findlocationinput_height = rand(10)+20
	findlocationinput_bottom = rand(50)
	findlocationinput_left = rand(70)
	findlocationinput_zindex = rand(5)+9994

	fblike_background = "##{rand(0xffffff).to_s(16)}"
	fblike_border = rand(2)
	fblike_width = rand(200)+100
	fblike_height = rand(10)+20
	fblike_bottom = rand(50)
	fblike_left =rand(60)
	fblike_position = "absolute"

	fbfan_background = "##{rand(0xffffff).to_s(16)}"
	fbfan_border = rand(5)
	fbfan_width = rand(10)+20
	fbfan_height = rand(10)+20
	fbfan_bottom = rand(50)
	fbfan_left =rand(90)
	fbfan_position = "absolute"

	twitter_background = "##{rand(0xffffff).to_s(16)}"
	twitter_border = rand(1)
	twitter_width = rand(10)+20
	twitter_height = rand(10)+20
	twitter_bottom = rand(60)
	twitter_left =rand(60)

	geo_rules=<<goof
"","","logo","logo",""
"","","fg","drsfostersmith_fg",""
"","","bg","makari_bg",""
"","","msg","default",""
"","","prefix","AccessoryGeeks",""
"$math.toInteger($geo.getDate('H')) > 20","Knife","logo","knifecenter_logo",""
"","","bg","knifecenter_bg",""
"","","msg","knifecenter",""
"","","prefix","knifecenter",""
"$math.toInteger($geo.getDate('d')) <= 14","Elite","logo","elitecarseats_logo",""
"","","bg","elitecarseats_bg",""
"","","msg","Gooooo",""
"","","prefix","elitecarseats",""
"$abandonSiteProducts.size() > 110","Bargain","logo","bargainmugs_logo",""
"","","bg","gnc_bg",""
"","","msg","poop",""
"","","prefix","gnc_t2",""
"$geo.getCountryName() != \"United States\"","NHL","logo","nhl_logo",""
"","","bg","nhl_bg",""
"","","msg","loop",""
"","","prefix","makari",""
"$geo.getRegion() == \"TN\" && $geo.getRegion() != \"HI\"","Betty","logo","bettymills_logo",""
"","","bg","bettymills_bg",""
"","","msg","stoop",""
"","","prefix","bettymills",""
"$geo.getRegion() == \"TN\" && $geo.getRegion() != \"HI\" && $geo.getRegionName() != \"Alaska\"","Avenue","logo","ave_logo",""
"","","bg","avenue_bg",""
"","","msg","goop",""
"","","prefix","avenue",""
"$geo.getCountryCode() != \"US\" && ($geo.getLongitude() < -111 || $geo.getLongitude() > -81)","Make Me Heal","logo","makeMeHeal_logo",""
"","","bg","makemeheal_bg",""
"","","msg","flop",""
"","","prefix","makemeheal",""
"$geo.getTimeZoneId() == \"America/Los_Angeles\"","My Spice","logo","myspicesage_logo",""
"","","bg","myspicesage_bg",""
"","","msg","slop",""
"","","prefix","mySpicesage",""
"$geo.getAreaCode() == \"480\"","Nuts Online","logo","nutonline_logo",""
"","","bg","nutonline_bg",""
"","","msg","crop",""
"","","prefix","nutsonline",""
"$geo.isCold() == true","Book It","logo","bookit_logo",""
"","","bg","bookit_bg",""
"","","msg","stop",""
"","","prefix","bookit",""
"$geo.getCity() != \"Tempe\"","Chasing Fireflies","logo","chasingfireflies_logo",""
"","","bg","chasingfireflies_bg",""
"","","msg","mop",""
"","","prefix","chasingfireflies",""
"$geo.getMetroCode() != \"753\"","Dr Foster","logo","drsfostersmith_logo",""
"","","msg","top",""
"","","prefix","drsfostersmith",""
goof

	begin
		site_name = site_data.execute("SELECT name FROM site_data WHERE siteId = '#{hash['siteId']}';")[0]['name']
	rescue NoMethodError
		next
	end
	
	$ff.link(:text, "Sites Index").click
	
	if site_name =~ /\d/
		$ff.link(:text, "9").click
	else
		$ff.link(:text, site_name[0].upcase).click
	end
	
	next if $ff.link(:text, site_name).exist? == false
	
	$ff.link(:text, site_name).click
	puts site_name
	
	like_url = $ff.text_field(:id, "url").value
	fan_url = "http://www.facebook.com/pages/#{CGI::escape(site_name)}"
	
	next if $ff.link(:text, hash['name']).exist? == false
	
	badgeTwitterShare = "Twitter Share #{hash['name']}"
	#badgeTwitterShareCSS
	badgeTwitterShareCountType = "vertical"
	badgeTwitterShareUrl = "http://www.twitter.com/#{CGI::escape(site_name)}"
	badgeTwitterShareRelatedUsers = "GSICommerce,eBay:The World's Online Marketplace"
	badgeTwitterShareVia = "fetchback"
	badgeTwitterShareText = "badgeTwitterShareText"
	#badgeTwitterShareTextCSS

	badge_crap =<<goof
"","","badgeFindLocation","#{site_name}",""
"","","badgeFindLocationButtonCSS","border:#{findlocationbutton_border}; width:#{findlocationbutton_width}px; height:23px;position:#{findlocationbutton_position};bottom:#{findlocationbutton_bottom}px;left:#{findlocationbutton_left}px;z-index:#{findlocationbutton_zindex};",""
"","","badgeFindLocationInputCSS","border:#{findlocationinput_border}; width:#{findlocationinput_width}px; height:#{findlocationinput_height}px;position:#{findlocationinput_position};bottom:#{findlocationinput_bottom}px;left:#{findlocationinput_left}px;z-index:#{findlocationinput_zindex};",""
"","","badgeFacebookLikeUrl","#{like_url}",""
"","","badgeFacebookLikeCSS","background:#{fblike_background}; border:#{fblike_border}; width:#{fblike_width}px; height:23px; position:absolute ;bottom:0px; left:45px; z-index:9998;",""
"","","badgeFacebookFanpageUrl","#{fan_url}",""
"","","badgeFacebookFanpageCSS","position:#{fbfan_position};width:#{fbfan_width}px;height:#{fbfan_height}px;left:#{fbfan_left}px;bottom:#{fbfan_bottom}px;background:#{fbfan_background} url('/serve/images/facebook.png');",""
"","","badgeTwitterFanpageUrl","#{twitter_url}",""
"","","badgeTwitterFanpageCSS","border:#{twitter_border};position:absolute;width:#{twitter_width}px;height:#{twitter_height}px;left:#{twitter_left}px;bottom:#{twitter_bottom}px;background:#{twitter_background} url('/serve/images/twitter.png');",""
"","","badgeTwitterShare","#{badgeTwitterShare}",""
"","","badgeTwitterShareCountType","#{badgeTwitterShareCountType}",""
"","","badgeTwitterShareRelatedUsers","#{badgeTwitterShareRelatedUsers}",""
"","","badgeTwitterShareVia","#{badgeTwitterShareVia}",""
"","","badgeTwitterShareUrl","#{badgeTwitterShareUrl}",""
"","","badgeTwitterShareCSS","border:none; overflow:hidden; position:absolute;bottom:0px;left:140px;z-index:9998;",""
"","","badgeTwitterShareText","#{badgeTwitterShareText}",""
"","","badgeTwitterShareTextCSS","color:red;z-index:9998;",""
goof
	
	$ff.link(:text, hash['name']).click
	puts hash['name']
	
	next if $ff.select_list(:id, "variableWorkspaceMode").exist? == false
	
	$ff.select(:id, "variableWorkspaceMode").select("CSV Format")
	$ff.text_field(:id, "textareaCSV").value=badge_crap
	$ff.select_list(:id, "variableWorkspaceMode").select("Table Format")
	$ff.button(:id, "Submit_0").click

end