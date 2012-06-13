class Account

  # TODO: Convert this class to using PageObject

  attr_accessor( :id, :name, :current_balance, :io_balance, :am, :status, :credit_enabled,
                 :client_branding, :site_ids, :site_names, :site_statuses, :site_cash_balances,
                 :site_io_balances, :site_autorenew_ios, :site_impressions, :site_incremental_conversions,
                 :site_inc_conv_values, :site_investments, :site_cpas )

  def initialize(browser)

    @browser = browser

    #Overview
    @id = browser.table(:id, "account_overview")[1][1].text
    @name = browser.text_field(:id, "TextField_0").value
    @current_balance = browser.table(:id, "account_overview")[3][1].text
    @io_balance = browser.table(:id, "account_overview")[4][1].text
    @am = (browser.select(:id, "PropertySelection").selected_options)[0].text
    @status = (browser.select(:id, "PropertySelection_0").selected_options)[0].text
    @credit_enabled = browser.table(:id, "account_overview")[7][1].text

    @client_branding = (browser.select(:id, "PropertySelection_1").selected_options)[0].text

    #Sites

    sites = browser.table(:id, "sites").to_a

    2.times { sites.delete_at(0) }

    @site_ids = {browser.link(:id, "ExternalLink_4").text => sites[0][0]}
    @site_names = {sites[0][0] => browser.link(:id, "ExternalLink_4").text}
    @site_statuses = {browser.link(:id, "ExternalLink_4").text => sites[0][3]}
    @site_cash_balances = {browser.link(:id, "ExternalLink_4").text => sites[0][4]}
    @site_io_balances = {browser.link(:id, "ExternalLink_4").text => sites[0][5]}
    @site_autorenew_ios = {browser.link(:id, "ExternalLink_4").text => sites[0][6]}
    @site_impressions = {browser.link(:id, "ExternalLink_4").text => sites[0][7]}
    @site_incremental_conversions = {browser.link(:id, "ExternalLink_4").text => sites[0][8]}
    @site_inc_conv_values = {browser.link(:id, "ExternalLink_4").text => sites[0][9]}
    @site_investments = {browser.link(:id, "ExternalLink_4").text => sites[0][10]}
    @site_cpas = {browser.link(:id, "ExternalLink_4").text => sites[0][11]}

    0.upto(sites.length - 2) do |i|

      @site_ids[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][0] #Key: Name, Value: ID
      @site_names[sites[i+1][0]] = browser.link(:id, "ExternalLink_4_#{i}").text # Key: ID, Value: Name
      @site_statuses[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][3]
      @site_cash_balances[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][4]
      @site_io_balances[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][5]
      @site_autorenew_ios[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][6]
      @site_impressions[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][7]
      @site_incremental_conversions[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][8]
      @site_inc_conv_values[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][9]
      @site_investments[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][10]
      @site_cpas[browser.link(:id, "ExternalLink_4_#{i}").text] = sites[i+1][11]

    end

  end

end

class SitesIndex

  include PageObject
  include HeaderBar
  include LeftMenuBar

  # TODO: Add custom methods for phase 2

end

class Site

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  # Overview
  text_field(:name, :id=>"siteName")
  alias site_name name

  def submit
    self.button(:id=>"Submit").click
    Site.new @browser
  end

  def id
    self.table(:id=>"site_overview")[1][1].text
  end
  text_field(:url, :id=>"url")

  select_list(:specialist, :id=>"specialistUser")
  select_list(:am, :id=>"accountManager")
  select_list(:crm, :id=>"relationManager")
  select_list(:implementation_manager, :id=>"implementationManager")
  div(:completion_percentage, :id=>"completionPercentage")
  checkbox(:cookie_override, :name=>"cookieOverride")
  checkbox(:shun_pixel_traffic, :id=>"shunPixelTraffic")
  checkbox(:dynamic_campaign_weighting, :id=>"performanceWeightEnabled")
  checkbox(:use_best_weighted, :id=>"bestWeightedWins")
  checkbox(:trusted_domains_enabled, :name=>"trustedDomainsEnabled")
  text_field(:trusted_domains, :id=>"trustedDomains")
  select_list(:conversion_window, :id=>"conversionWindowEnum")
  select_list(:stop_pixel_period, :id=>"stopPixelEnum")
  select_list(:status, :id=>"status")
  select_list(:control_campaign_percent, :id=>"abTestPercEnum")
  checkbox(:enable_recommendations, :id=>"recoEnabled")
  checkbox(:enable_category_recommendations, :id=>"categoryRecoEnabled")
  checkbox(:show_popular_browsed,:id=>"showPopularBrowsed")
  checkbox(:vtc_manager, :id=>"campaignLevelVTC")
  checkbox(:enable_image_proxy, :id=>"imageProxyEnabled")
  checkbox(:enable_server_side_cookies, :id=>"serverSideCookiesEnabled")
  checkbox(:enable_extended_conversion_referrer, :id=>"extendedConversionReferrerEnabled")
  text_field(:sales_force_account_link, :id=>"crmAccountUrl")
  checkbox(:pup_list, :id=>"pupList")
  checkbox(:site_level_pricing, :id=>"pricingControlEnabled")
  checkbox(:third_party_billing, :id=>"thirdPartyBilling")

    # Pricing
  text_field(:cpm, :id=>"CPM")
  text_field(:cpa, :id=>"CPA")
  text_field(:percent_revshare, :id=>"percentRevenueShare")
  text_field(:cpc, :id=>"CPC")
  select_list(:include_vt_within, :id=>"viewThroughTimeEnum")
  text_field(:target_cpc_ecpm, :id=>"targetCPC_ECPM")
  text_field(:max_cpc_bid_price, :id=>"maxCPCBidPrice")
  text_field(:cpe, :id=>"CPE")
  text_field(:target_cpe_ecpm, :id=>"targetCPE_ECPM")
  text_field(:max_cpe_bid_price, :id=>"maxCPEBidPrice")
  text_field(:max_ecpm, :id=>"maxECPM")
  text_field(:goal_cpa, :id=>"goalCPA")
  text_field(:goal_cpc, :id=>"goalCPC")
  checkbox(:flat_fee, :name=> "flatFee")
  text_field(:baseline_return_conversions, :id=>"baselineReturnConversions")
  text_field(:control_group_conversion_rate, :id=>"controlGroupeConverstionRate")
  text_field(:conversion_value, :id=>"conversionValue")
  checkbox(:revenue_pixel, :name=> "revenuePixel")
  text_field(:minimum_charge_per_period, :id=>"minimumChargePerPeriod")
  # Potential for confusion, here:
  text_field(:charge_period, :id=>"chargePeriod")
  text_field(:charge_period_start, :id=>"chargePeriodStart")

  # Overview Site Statistics
  def overview_site_stats
    table = self.div(:id=>"If_58").table(:id=>"sites").to_a
    table.flatten!
  end

  def cash_balance
    overview_site_stats[11]
  end
  def io_balance
    overview_site_stats[12]
  end
  def auto_renew_io
    overview_site_stats[13]
  end
  def impression_count
    overview_site_stats[14]
  end
  def incremental_conversions
    overview_site_stats[15]
  end
  def incremental_conversions_value
    overview_site_stats[16]
  end
  def investment
    overview_site_stats[17]
  end
  def overview_cpa
    overview_site_stats[18]
  end

  def campaigns_table
    self.div(:id=>"If_71_0").table(:id=>"sites")
  end

  #Campaigns info
  def campaigns_array
    array = campaigns_table.to_a
    2.times { array.delete_at(0) }
    array
  end

  CAMPAIGN_ID = 0
  CAMPAIGN_NAME = 2
  CAMPAIGN_IMPS = 5
  CAMP_INC_CONV = 6
  CAMP_ICV = 7
  CAMP_INVESTMENT = 8
  CAMPAIGN_CPA = 9

  def campaigns
    make_camp_hash(2, CAMPAIGN_ID)
  end

  def campaign_names
    make_camp_hash(CAMPAIGN_ID, 2)
  end

  def performance_weight
    hash = {}
    0.upto(campaigns_array.length - 1) do |i|
      hash.store(campaigns_array[i][CAMPAIGN_NAME], self.text_field(:id => "#{campaigns_array[i][CAMPAIGN_ID]}").value)
    end
    hash
  end

  def campaign_impressions
    make_camp_hash(CAMPAIGN_NAME, CAMPAIGN_IMPS)
  end

  def campaign_ics
    make_camp_hash(CAMPAIGN_NAME, CAMP_INC_CONV)
  end

  def campaign_ics_value
    make_camp_hash(CAMPAIGN_NAME, CAMP_ICV)
  end

  def campaign_investment
    make_camp_hash(CAMPAIGN_NAME, CAMP_INVESTMENT)
  end

  def campaign_cpa
    make_camp_hash(CAMPAIGN_NAME, CAMPAIGN_CPA)
  end

  # Returns the name of the default campaign
  def default_campaign
    # Get row id for selected radio button...
    tid = "x"
    campaigns_table.radios(:id=>/Any_\d/).each do |radio|
      if radio.set?
        tid = radio.parent.parent.parent.parent.id
        break
      else

      end
    end
    campaigns_table.row(:id=>tid).link(:id=>/ExternalLink_3_/).text
  end

  #Pepperjam tracking links
  affiliate_table = []
  #affiliate_table1 = []
  #affiliate_table2 = []

  def showhide_affiliate_links
    affiliate_table.div(:id=>"afl_show").link.click
  end

  def affiliate_table
    self.table(:id, "affiliate")
  end
  #affiliate_table1 = browser.table(:id, "affiliate_0").to_a
  #affiliate_table2 = browser.table(:id, "affiliate_1").to_a

  def pepperjam_url_1
    affiliate_table.row(:index=>2).text
  end

  def pepperjam_url_2
    affiliate_table.row(:index=>4).text
  end
  #@test_redirection_URL_1 = affiliate_table1[1][0]
  #@test_redirection_URL_2 = affiliate_table1[2][0]
  #@test_redirection_URL_3 = affiliate_table2[1][0]
  #@test_redirection_URL_4 = affiliate_table2[2][0]

  # Private Methods
  private

  def make_camp_hash(key, value)
    hash = {}
    0.upto(campaigns_array.length - 1) do |i|
      hash.store(campaigns_array[i][key], campaigns_array[i][value])
    end
    hash
  end

end

class IOAccountability

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  # TODO: Add custom methods for phase 2
  text_field(:io_amount, :id=>"amount")

end

class PUPList

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  # TODO: Add custom methods for phase 2

  checkbox(:received_creative_assets, :id=>"creativeAssetsReceived")

end

class Campaign

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  def id
    self.form(:id=>"Form_0").table(:class=>"styled blacklinks")[2][0].text
  end

  text_field(:campaign_name, :id=>"adminCampaignName")
  text_field(:cpm, :id=>"CPM")
  text_field(:cpa, :id=>"CPA")
  text_field(:percent_revshare, :d=>"revenueShare")
  text_field(:cpc, :id=>"cpc")
  text_field(:target_ecpm, :id=>"targetCpcEcpm")
  select_list(:include_VT_within, :id=>"PropertySelection")
  text_field(:max_bid_price,:id=>"maxCpcPrice")
  text_field(:max_ecpm, :id=>"maxCpaEcpm")
  checkbox(:dynamic_creative_weighting, :id=>"dynamicWeightBoolean")
  checkbox(:creative_plus_pdc, :id=>"disableDirectPdc")
  select_list(:status, :id=>"status")
  text_field(:priority_weight, :id=>"priorityWeight")
  text_field(:flat_fee_value, :id=>"flatFeeValue")

  def pdj_nonsec_pixel
    stripify(self.div(:id, "pdjNonsecure").text)
  end

  def pdj_sec_pixel
    stripify(self.div(:id, "pdjSecure").text)
  end

  def pdj_success_pixel
    stripify(self.div(:id, "pdjSuccess").text)
  end

  link(:uat_pixels, :id=>"uat_link")

  def uat_nonsec_pixel
    stripify(self.div(:id, "uatNonsecure").text)
  end

  def uat_sec_pixel
    stripify(self.div(:id, "uatSecure").text)
  end

  def uat_success_pixel
    stripify(self.div(:id, "uatSuccess").text)
  end

  def ssl_href
    self.link(:text=>"SSL").href
  end

  def non_ssl_href
    self.link(:text=>"Non-SSL").href
  end

  table(:creatives_table, :id=>"creativesTable")
  table(:ad_tags_table, :id=>"stdAdvancedSettings_0")
  select_list(:worksheet_view_mode, :id=>"variableWorkspaceMode")
  button(:update_worksheet, :name=>"Submit_0")
  button(:preview_worksheet, :name=>"Submit_1")
  text_area(:variable_worksheet_csv, :id=>"textareaCSV")

  # Returns an array containing the name values of all creatives listed.
  def creative_names
    array = []
    self.table(:id=>"creativesTable").rows.each do |row|
      if row.id =~ /For_/
        array << row.link(:id=>/ExternalLink_\d/).text
      end
    end
    array
  end

  # Returns an array containing the names of the network adtags listed
  # in the Standard Advanced Settings table.
  def network_adtag_names
    array = []
    self.table(:id=>"stdAdvancedSettings_0").rows.each do |row|
      if row.id =~ /For_\d/
        array << row.link(:id=>/ExternalLink_\d/).text
      end
    end
    array
  end

  # This method opens an ad tag listing on a campaign page.
  # Since doing this opens the link in a new tab, this method
  # closes the first tab and then switches to the new tab.
  def open_ad_tag(ad_tag_name)
    self.link(:text=>ad_tag_name).click
    self.window(:title, "FetchBack Campaign").close
    self.window(:title, "FetchBack NetworkAdTag").use
    AdTag.new @browser
  end

end

class KeywordMatching

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  button(:add_multiple_keywords, :class=>"controlButton showAddKeywordsForm")
  text_area(:keywords, :class=>"keywordInput")
  button(:submit_keywords, :class=>"controlButton submitAddKeywordsForm")

end

class DynamicManager

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class DQS

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  def enable
    @browser.checkbox(:class, "isEnabled")
  end

  def submit
    @browser.button(:class, "submitButton")
  end

  def test
    @browser.button(:id, "testUrlButton")
  end

  def clear
    @browser.button(:id, "clearUrlButton")
  end

  def show_hide(index)
    @browser.span(:class=>"showhide", :index=>index).fire_event("onclick")
  end

  def type(index)
    @browser.select(:class=>"siteActionTypeId",:index=>index)
  end

  def description(index)
    @browser.text_field(:class=>"description",:index=>index)
  end

  def cpa_goal(index)
    @browser.text_field(:class=>"cpaGoal",:index=>index)
  end

  def add(index)
    @browser.image(:title=>"add",:index=>index).fire_event("onclick")
  end

  def copy(index)
    @browser.image(:title=>"copy",:index=>index).fire_event("onclick")
  end

  def delete(index)
    @browser.image(:title=>"delete",:index=>index)
  end

  def url_fragment(index)
    @browser.text_field(:class=>"siteActionMatchString",:index=>index)
  end

  def rule_type(index)
    @browser.select(:class=>"siteActionMatchRuleTypeId",:index=>index)
  end

  def name(index)
    @browser.select(:class=>"creativeId",:index=>index)
  end

  def status(index)
    @browser.select(:class=>"statusId",:index=>index)
  end

  def order_by(index)
    @browser.select(:class=>"creativeOrderBy",:index=>index)
  end

  def weight(index)
    @browser.text_field(:class=>"weight",:index=>index)
  end

  def sequence(index)
    @browser.text_field(:class=>"sequencer",:index=>index)
  end

  def click_url(index)
    @browser.text_field(:class=>"clickUrl",:index=>index)
  end

  def preview(index)
    @browser.image(:title=>"preview",:index=>index).fire_event("onclick")
  end

  def test_url
    @browser.text_field(:id, "testUrl")
  end

  def edit(index)
    @browser.image(:title=>"edit",:index=>index).fire_event("onclick")
  end
end

class AdTag

  attr_accessor( :id, :network, :name, :floodlight, :keyword_enabled, :status, :pixel_age,
                 :cpm, :frequency_cap, :pixel_number, :floodlight_age, :associated_account, :end_preview,
                 :special_notes, :pixel_tag, :ssl_pixel_tag, :success_pixel_tag, :ssl_success_pixel_tag,
                 :email_contact, :medium_rectangle, :skyscraper, :pop, :leaderboard, :banner, :wide_skyscraper,
                 :vertical_banner, :square, :rectangle, :vertical_rectangle, :transition_ads, :pop_720x300,
                 :pop_250x250, :half_page_ad, :mrect_id, :sky_id, :pop_id, :lead_id, :banner_id, :widesky_id,
                 :vbanner_id, :square_id, :rect_id, :vrect_id, :trans_id, :pop720x300_id, :pop250x250_id, :halfpage_id,
                 :ids, :button_2, :button_2_id, :micro_bar, :micro_bar_id, :exp_lead, :exp_lead_id, :exp_widesky,
                 :exp_medrec, :exp_sky, :exp_widesky_id, :exp_medrec_id, :exp_sky_id)

  def initialize(browser)

    @browser = browser

    html = browser.html

    @id = browser.table(:class, "corner_top_right_only styled")[1][0].text
    @network = browser.link(:id, "ExternalLink_0").text
    @name = browser.text_field(:id, "TextField_0").value
    @floodlight = browser.checkbox(:name, "urlOnly").checked?
    @keyword_enabled = browser.checkbox(:name, "Checkbox").checked?
    @status = (browser.select(:id, "PropertySelection_0").selected_options)[0]
    @pixel_age = browser.text_field(:id, "TextField_1").value
    @cpm = browser.text_field(:id, "TextField_2").value
    @frequency_cap = browser.text_field(:id, "TextField_3").value
    @pixel_number = browser.text_field(:id, "TextField_4").value
    @floodlight_age = browser.text_field(:id, "TextField_5").value
    @associated_account = browser.text_field(:id, "TextField_6").value
    @end_preview = browser.text_field(:id, "DatePicker").value
    @special_notes = browser.text_field(:id, "TextArea").value
    @pixel_tag = browser.text_field(:id, "negativeMatch").value
    @ssl_pixel_tag = browser.text_field(:id, "negativeSSLMatch").value
    @success_pixel_tag = browser.text_field(:id, "positiveMatch").value
    @ssl_success_pixel_tag = browser.text_field(:id, "positiveSSLMatch").value
    @email_contact = browser.checkbox(:name, "Checkbox_1").checked?

    # Creative types (check boxes)

    @medium_rectangle = browser.checkbox(:name, "Checkbox_0_4").checked?
    @skyscraper = browser.checkbox(:name, "Checkbox_0").checked?
    @pop = browser.checkbox(:name, "Checkbox_0_0").checked?
    @leaderboard = browser.checkbox(:name, "Checkbox_0_1").checked?
    @banner = browser.checkbox(:name, "Checkbox_0_2").checked?
    @wide_skyscraper = browser.checkbox(:name, "Checkbox_0_3").checked?
    @vertical_banner = browser.checkbox(:name, "Checkbox_0_5").checked?
    @square = browser.checkbox(:name, "Checkbox_0_6").checked?
    @rectangle = browser.checkbox(:name, "Checkbox_0_7").checked?
    @vertical_rectangle = browser.checkbox(:name, "Checkbox_0_8").checked?
    @transition_ads = browser.checkbox(:name, "Checkbox_0_9").checked?
    @pop720x300 = browser.checkbox(:name, "Checkbox_0_10").checked?
    @pop250x250 = browser.checkbox(:name, "Checkbox_0_11").checked?
    @half_page_ad = browser.checkbox(:name, "Checkbox_0_12").checked?
    @button_2 = browser.checkbox(:name, "Checkbox_0_13").checked?
    @micro_bar = browser.checkbox(:name, "Checkbox_0_14").checked?
    @exp_lead = browser.checkbox(:name, "Checkbox_0_15").checked?
    @exp_widesky = browser.checkbox(:name, "Checkbox_0_16").checked?
    @exp_medrec = browser.checkbox(:name, "Checkbox_0_17").checked?
    @exp_sky = browser.checkbox(:name, "Checkbox_0_18").checked?

    # Network Ad Tag IDs themselves

    @ids = []  # An array to store all active ids, for easy manipulation later.

    if @medium_rectangle == true
      @mrect_id = html[/\d+(?=&amp;type=mrect'&gt;&lt;)/]
      @ids << @mrect_id
    else
      @mrect_id = ""
    end

    if @skyscraper == true
      @sky_id = html[/\d+(?=&amp;type=sky'&gt;&lt;)/]
      @ids << @sky_id
    else
      @sky_id = ""
    end

    if @pop == true
      @pop_id = html[/\d+(?=&amp;type=pop'&gt;&lt;)/]
      @ids << @pop_id
    else
      @pop_id = ""
    end

    if @leaderboard == true
      @lead_id = html[/\d+(?=&amp;type=lead'&gt;&lt;)/]
      @ids << @lead_id
    else
      @lead_id = ""
    end

    if @banner == true
      @banner_id = html[/\d+(?=&amp;type=banner'&gt;&lt;)/]
      @ids << @banner_id
    else
      @banner_id = ""
    end

    if @wide_skyscraper == true
      @widesky_id = html[/\d+(?=&amp;type=widesky'&gt;&lt;)/]
      @ids << @widesky_id
    else
      @widesky_id = ""
    end

    if @vertical_banner  == true
      @vbanner_id = html[/\d+(?=&amp;type=vbanner'&gt;&lt;)/]
      @ids << @vbanner_id
    else
      @vbanner_id = ""
    end

    if @square == true
      @square_id = html[/\d+(?=&amp;type=square'&gt;&lt;)/]
      @ids << @square_id
    else
      @square_id = ""
    end

    if @rectangle == true
      @rect_id = html[/\d+(?=&amp;type=rect'&gt;&lt;)/]
      @ids << @rect_id
    else
      @rect_id = ""
    end

    if @vertical_rectangle == true
      @vrect_id = html[/\d+(?=&amp;type=vrect'&gt;&lt;)/]
      @ids << @vrect_id
    else
      @vrect_id = ""
    end

    if @transition_ads == true
      @trans_id = html[/\d+(?=&amp;type=trans'&gt;&lt;)/]
      @ids << @trans_id
    else
      @trans_id = ""
    end

    if @pop720x300 == true
      @pop720x300_id = html[/\d+(?=&amp;type=pop720x300'&gt;&lt;)/]
      @ids << @pop720x300_id
    else
      @pop720x300_id = ""
    end

    if @pop250x250 == true
      @pop250x250_id = html[/\d+(?=&amp;type=pop250x250'&gt;&lt;)/]
      @ids << @pop250x250_id
    else
      @pop250x250_id = ""
    end

    if @half_page_ad == true
      @halfpage_id = html[/\d+(?=&amp;type=halfpage'&gt;&lt;)/]
      @ids << @halfpage_id
    else
      @halfpage_id = ""
    end

    if @button_2 == true
      @button_2_id = html[/\d+(?=&amp;type=button2'&gt;&lt;)/]
      @ids << @button_2_id
    else
      @button_2_id = ""
    end

    if @micro_bar == true
      @micro_bar_id = html[/\d+(?=&amp;type=micro'&gt;&lt;)/]
      @ids << @micro_bar_id
    else
      @micro_bar_id = ""
    end

    if @exp_lead == true
      @exp_lead_id = html[/\d+(?=&amp;type=exlead'&gt;&lt;)/]
      @ids << @exp_lead_id
    else
      @exp_lead_id = ""
    end

    if @exp_widesky == true
      @exp_widesky_id = html[/\d+(?=&amp;type=exlead'&gt;&lt;)/]
      @ids << @exp_widesky_id
    else
      @exp_widesky_id = ""
    end

    if @exp_medrec == true
      @exp_medrec_id = html[/\d+(?=&amp;type=exlead'&gt;&lt;)/]
      @ids << @exp_medrec_id
    else
      @exp_medrec_id = ""
    end

    if @exp_sky == true
      @exp_sky_id = html[/\d+(?=&amp;type=exlead'&gt;&lt;)/]
      @ids << @exp_sky_id
    else
      @exp_sky_id = ""
    end

  end
end

class NetworksIndex

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class Network

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  def id
    @browser.table(:id, "network_overview")[1][1].text
  end

  def name
    @browser.text_field(:id, "TextField_0")
  end

  def status
    @browser.select(:id, "PropertySelection")
  end

  def url
    @browser.text_field(:id, "TextField_1")
  end

  def username
    @browser.text_field(:id, "TextField_2")
  end

  def password
    @browser.text_field(:id, "TextField_3")
  end

  def email_addresses
    @browser.text_field(:id, "TextField_4")
  end

  def update
    @browser.button(:id, "Submit").click
  end

end

class Creative

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  def id
    self.table(:id, "creative_overview")[2][2].text
  end

  text_field(:ordered_sequence, :id=>"sequencer")
  text_field(:creative_name, :id=>"name")
  checkbox(:dynamic_weighting, :name=>"Checkbox")
  select_list(:type, :id=>"PropertySelection")
  select_list(:status, :id=>"PropertySelection_0")
  text_field(:weighted_value, :id=>"TextField_0")
  text_field(:click_URL, :id=>"clickUrl")
  checkbox(:third_party_clicktracking, :id=>"thirdPartyClicktrackingEnabled")
  link(:showhide_template, :id=>"Any_3_0")
  link(:showhide_clicktrack, :id=>"Any_2_0")
  text_field(:html_template, :id=>"htmlTemplate")
  text_field(:third_party_tag, :id=>"htmlTemplate")
  button(:autodetect, :value=>"Autodetect")
  text_field(:impression_tracking_pixel, :id=>"impTracking")
  div(:template_fields, :id=>"templateDiv")
  select_list(:template_third_party, :id=>"templateThirdPartySelector")
  text_field(:global_redirect_url, :id=>"globalClick")
  text_field(:global_query_string, :id=>"globalLanding")
  text_field(:product_redirect_url, :id=>"productClick")
  text_field(:product_query_string, :id=>"productLanding")
  text_field(:alternative_redirect_url, :id=>"alternativeClick")
  text_field(:alternative_query_string, :id=>"alternativeLanding")
  file_field(:upload_file, :id=>"Upload")
  button(:upload_button, :id=>"Submit_1")

  def update
    @browser.button(:id=>"Submit").click
    Creative.new @browser
  end

  def create
    @browser.button(:id=>"Submit_0").click
    Creative.new @browser
  end

end

class User

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  text_field(:username, :id=>"TextField_0")
  text_field(:password, :id=>"password")
  text_field(:first_name, :id=>"TextField_1")
  text_field(:last_name, :id=>"TextField_2")
  text_field(:email, :id=>"TextField_3")
  text_field(:phone, :id=>"TextField_4")
  checkbox(:is_enabled, :id=>"enabled_check")
  checkbox(:is_admin, :id=>"admin_check")
  checkbox(:is_employee, :id=>"employee_check")
  checkbox(:is_ess_administrator, :id=>"essAdmin_check")
  checkbox(:is_data_partner, :id=>"dataPartnerUser_check")
  select_list(:for_data_partner,:id=>"PropertySelection")
  button(:create, :value=>"Create")
  button(:update, :id=>"Submit")
  select_list(:advertisers_available, :id=>"Palette_0_avail")
  select_list(:advertisers_selected, :id=>"Palette_0")
  link(:advertisers_select, :href=>"javascript:tapestry.select_Palette_0();")
  link(:advertisers_deselect, :href=>"javascript:tapestry.deselect_Palette_0();")
  button(:advertisers_submit, :id=>"Submit_0")
  select_list(:pages_available, :id=>"Palette_2_avail")
  select_list(:pages_selected, :id=>"Palette_2")
  link(:pages_select, :href=>"javascript:tapestry.select_Palette_2();")
  link(:pages_deselect, :href=>"javascript:tapestry.deselect_Palette_2();")
  button(:pages_submit, :id=>"Submit_1")

end

class Misc

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  def clear_cache
    self.link(:id, "clearCache").click
    # Need to work on pop-up support, here...
    self.javascript_dialog.button('OK').click
  end

  def project_version
    text = self.div(:class=>"box").p.text
    text[/\d.\d.\d/]
  end

end

class CookieAnalysis

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  table(:campaign_history, :id=>"sites")

end

class DataPartnersIndex

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class DataPartners

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class DataPartnerSettings

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class ThirdPartyTagIndex

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class ThirdPartyTag

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class GoalSetting

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

  select_list(:select_account_manager, :id=>"PropertySelection")
  select_list(:select_site_status, :id=>"PropertySelection_0")
  select_list(:select_month_and_year, :id=>"PropertySelection_1")
  button(:show_report, :id=>"Submit")


end

class Auditor

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class PupListReport

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar

end

class AccountsIndex

  include PageObject
  include NavigationalAids
  include HeaderBar
  include LeftMenuBar


end

class LoginPage

  include PageObject

  text_field(:user, :name=>"j_username")
  text_field(:password, :name=>"j_password")
  button(:login, :name=>"submit")
  link(:privacy_policy, :text=>"Privacy Policy")

  def log_in(user, pass)
    self.user=user
    self.password=pass
    self.login
    self.link(:text=>"Privacy Policy").wait_until_present
    AccountsIndex.new @browser
  end

end