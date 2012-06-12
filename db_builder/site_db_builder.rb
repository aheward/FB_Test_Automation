=begin

This script builds the SQLite3 test database from CSV files
obtained from iobox22.

Generally, the creative_data.csv and the products.csv will
need to be groomed a bit before running this script, since
they will usually contain bad characters.

=end
# coding: UTF-8
#!/usr/bin/env ruby
require '../config/env.rb'
Dir.chdir(File.dirname(__FILE__))

#SITES_DB.results_as_hash = true

#Site Data...

sites = []

File.open("site_data.csv").each do | line |

	sites << line.chomp
	
end

sites.delete_at(0)

SITES_DB.execute(%|DROP TABLE IF EXISTS site_data;|)

sites_table_SQL =<<doof
CREATE TABLE site_data (
	siteId INT PRIMARY KEY,
	advertiserId INT,
	name BLOB,
	url BLOB,
	userName BLOB,
	cookieOverride INT,
	showPopularBrowsed INT,
	viewThroughTime INT,
	conversionWindow BLOB,
	trustedDomains BLOB,
	trustedDomainsEnabled INT,
	ImageProxyEnabled INT,
	performanceWeightEnabled INT,
	bestWeightedWins INT,
	categoryRecoEnabled INT,
	recoEnabled INT,
	cpa BLOB,
	cpe BLOB,
	cpm BLOB,
	cpc BLOB,
	flatFee INT,
	revenueShare BLOB,
	conversionValue BLOB,
	maxCpcPrice BLOB,
	targetCpeEcpm BLOB,
	targetCpcEcpm BLOB,
	cpcGoal BLOB,
	cpaGoal BLOB,
	maxCpePrice BLOB,
	maxCpaEcpm BLOB,
	abTestPerc BLOB
);
doof

SITES_DB.execute(sites_table_SQL)

sites.each do | line |
	
	line.gsub!(%|,|, %|","|)

	sql =<<doof
		INSERT INTO site_data (
			siteId, advertiserId, name, url, userName, cookieOverride, showPopularBrowsed, viewThroughTime, conversionWindow, trustedDomains, trustedDomainsEnabled, ImageProxyEnabled, performanceWeightEnabled, bestWeightedWins, categoryRecoEnabled, recoEnabled, cpa, cpe, cpm, cpc, flatFee, revenueShare, conversionValue, maxCpcPrice, targetCpeEcpm, targetCpcEcpm, cpcGoal, cpaGoal, maxCpePrice, maxCpaEcpm, abTestPerc			
			)
			VALUES
			( "#{line}" )
		;	
doof

	SITES_DB.execute(sql)

end
puts "Sites table done."
puts SITES_DB.execute(%|SELECT * FROM site_data WHERE siteId = '1327';|)
#=end
#=begin
# Campaign Data
campaigns = []

File.open("campaign_data.csv").each do | line |
	#puts line
	campaigns << line.chomp
end

SITES_DB.execute(%|DROP TABLE IF EXISTS campaign_data;|)

campaigns_table_SQL =<<doof
CREATE TABLE campaign_data (
	campaignId INT PRIMARY KEY,
	siteId INT,
	name BLOB,
	performanceWeight BLOB,
	dynamicWeightBoolean INT,
	disableDirectPdc INT,
	cpc BLOB,
	cpa BLOB,
	cpm BLOB,
	cpe BLOB,
	revenueShare BLOB,
	flatFeeBoolean INT,
	flatFee BLOB,
	maxCpaEcpm BLOB,
	maxCpePrice BLOB,
	maxCpcPrice BLOB,
	targetCpcEcpm BLOB,
	targetCpeEcpm BLOB
);
doof

SITES_DB.execute(campaigns_table_SQL)

campaigns.each do | line |

	array = line.split("\t")
	array[2].gsub!(%|'|,%||)
	array[2].gsub!(%|"|,%||)
	array[2].gsub!(%|\\|,%||)
	array[2].gsub!(%|/|,%||)
	array[2].gsub!(%|?|,%||)

	sql =<<doof
		INSERT INTO campaign_data (
			campaignId,siteId,name,performanceWeight,dynamicWeightBoolean,disableDirectPdc,cpc,cpa,cpm,cpe,revenueShare,flatFeeBoolean,flatFee,maxCpaEcpm,maxCpePrice,maxCpcPrice,targetCpcEcpm,targetCpeEcpm
			)
			VALUES
			( "#{array[0]}","#{array[1]}","#{array[2]}","#{array[3]}","#{array[4]}","#{array[5]}","#{array[6]}","#{array[7]}","#{array[8]}","#{array[9]}","#{array[10]}","#{array[11]}","#{array[12]}","#{array[13]}","#{array[14]}","#{array[15]}","#{array[16]}","#{array[17]}" )
		;	
doof

	SITES_DB.execute(sql)

end

puts "Campaign table done."
puts SITES_DB.execute(%|SELECT * FROM campaign_data WHERE siteId = '1327';|)

# Network Ad Tag Data
ad_tags = []

File.open("ad_tag_data.csv").each do | line |
	#puts line
	ad_tags << line.chomp
	
end

ad_tags.delete_at(0)

SITES_DB.execute(%|DROP TABLE IF EXISTS network_adtag_data;|)

adtag_table_SQL =<<doof
CREATE TABLE network_adtag_data (
	networkAdTagId,
	campaignId,
	siteId,
	networkId,
	primaryId,
	name,cpm,
	pixelAge,
	creativeTypeId,
	keywordEnabled
);
doof

SITES_DB.execute(adtag_table_SQL)

ad_tags.each do | line |
	line.gsub!(%|,|, %|","|)
	sql =<<doof
		INSERT INTO network_adtag_data (
			networkAdTagId,campaignId,siteId,networkId,primaryId,name,cpm,pixelAge,creativeTypeId,keywordEnabled
			)
			VALUES
			( "#{line}" )
		;	
doof

	SITES_DB.execute(sql)

end

puts "Ad Tags table done."
puts SITES_DB.execute(%|SELECT * FROM network_adtag_data WHERE siteId = '1327';|)
#=end
# Creative Data

creatives = []

File.open("creative_data.csv").each do | line |
	#puts line
	creatives << line.chomp
	
end

SITES_DB.execute(%|DROP TABLE IF EXISTS creative_data;|)

creative_table_SQL =<<doof
CREATE TABLE creative_data (
	creativeId INT PRIMARY KEY,
	campaignId INT,
	siteId INT,
	advertiserId INT,
	creativeTypeId INT,
	name BLOB,
	sequencer BLOB,
	dynamicWeightBoolean INT,
	weight BLOB,
	thirdPartyClicktracking INT
);
doof

SITES_DB.execute(creative_table_SQL)

creatives.each do | line |
	
	array = line.split("\t")
	array[5].gsub!(%|'|,%||)
	array[5].gsub!(%|"|,%||)
	array[5].gsub!(%|\\|,%||)
	array[5].gsub!(%|/|,%||)
	array[5].gsub!(%|?|,%||)
	
	sql =<<doof
		INSERT INTO creative_data (
			creativeId,campaignId,siteId,advertiserId,creativeTypeId,name,sequencer,dynamicWeightBoolean,weight,thirdPartyClicktracking
			)
			VALUES
			( "#{array[0]}","#{array[1]}","#{array[2]}","#{array[3]}","#{array[4]}","#{array[5]}","#{array[6]}","#{array[7]}","#{array[8]}","#{array[9]}" )
		;	
doof

	SITES_DB.execute(sql)

end

puts "Creatives table done."
puts SITES_DB.execute(%|SELECT * FROM creative_data WHERE siteId = '1327';|)

#=end
# VTC Merit Data

merit = []

File.open("vt_merit_data.csv").each do | line |
	#puts line
	merit << line.chomp
	
end

merit.delete_at(0)

SITES_DB.execute(%|DROP TABLE IF EXISTS vt_merit_data;|)

merit_table_SQL =<<doof
CREATE TABLE vt_merit_data (
	siteId INT,
	period INT,
	value BLOB
);
doof

SITES_DB.execute(merit_table_SQL)

merit.each do | line |
	line.gsub!(%|,|, %|","|)
	sql =<<doof
		INSERT INTO vt_merit_data (
			siteId,period,value
			)
			VALUES
			( "#{line}" )
		;	
doof

	SITES_DB.execute(sql)

end

puts "Merit table done."
puts SITES_DB.execute(%|SELECT * FROM vt_merit_data WHERE siteId = '1327';|)

#=end
#=begin
# Keywords

keywords = []

File.open("keyword_data.csv").each do | line |
	#puts line
	keywords << line.chomp
	
end

keywords.delete_at(0)

SITES_DB.execute(%|DROP TABLE IF EXISTS keywords;|)

keyword_table_SQL =<<doof
CREATE TABLE keywords (
	siteId INT,
	campaignId INT,
	keyword BLOB,
	checksum BLOB
);
doof

SITES_DB.execute(keyword_table_SQL)

keywords.each do | line |
	line.gsub!(%|,|, %|","|)
	sql =<<doof
		INSERT INTO keywords (
			siteId,campaignId,keyword,checksum
			)
			VALUES
			( "#{line}" )
		;	
doof

	SITES_DB.execute(sql)

end

update_sql =<<doof
ALTER TABLE keywords
ADD COLUMN full_keyword BLOB;
doof

SITES_DB.execute(update_sql)

camp_ids = SITES_DB.execute(%|SELECT DISTINCT campaignId FROM keywords;|).flatten!

camp_ids.each do | id |

	keys_sql =<<goof
	SELECT GROUP_CONCAT(keyword, "+"), checksum FROM keywords WHERE campaignId = '#{id}' GROUP BY checksum;
goof

	keys = SITES_DB.execute(keys_sql)
	keys.delete_if { | key | key[1] == "" }
	
	keys.each do | key |
		
		full_key = key[0]
		chcksum = key[1]
		
		full_kw_sql =<<doof
			UPDATE keywords
			SET
				full_keyword = "#{full_key}"
			WHERE
				checksum = "#{chcksum}"
				;
doof
		
		SITES_DB.execute(full_kw_sql)
		
	end

end

puts "Keywords table done."
SITES_DB.results_as_hash = true
p SITES_DB.execute(%|SELECT * FROM keywords WHERE siteId = '2187';|)
SITES_DB.results_as_hash = false

# Products...
#=begin
products = []

File.open("products.csv").each do | line |
	line.gsub!(%|"|, %||)
	line.gsub!(%|christian videos|, %|http://www.nestentertainment.com/crocodile-embossed-wpurse-handle-med-brg-bible-cover_p26090.aspx|)
	line.gsub!(%|Dimplex%2033\"%20Electric%20|,%|Dimplex%2033%20Electric%20|)
	line.gsub!(%|,h|, %|,"h|)
	products << line.chomp
end

#products.delete_at(0)
#=begin

SITES_DB.execute(%|DROP TABLE IF EXISTS product_links;|)

table_SQL =<<goof
CREATE TABLE product_links (
	siteId INT,
	campaignId INT,
	url BLOB
);
goof

SITES_DB.execute(table_SQL)
#=end

products.each do | line |

	products_SQL =<<doof
		INSERT INTO product_links (
			siteId, campaignId, url )
			VALUES
			( #{line}" )
		;	
doof

	SITES_DB.execute(products_SQL)

end

puts "Products links done."
puts SITES_DB.execute(%|SELECT * FROM product_links WHERE siteId = '1327';|)
#=end