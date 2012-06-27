# coding: UTF-8

module HeaderBar

  include PageObject

  def logo?
    self.image(:src=>"images/logo.gif").present?
  end

  def account_home # TODO - This is going to be wrong a lot
    self.link(:text=>"Account Home").click
    AccountsIndex.new @browser
  end

  def campaigns
    self.link(:text=>"Campaigns", :href=>/page\=Site/).click
    Site.new @browser
  end

  def analytics
    # TODO
  end

  def my_account
    # TODO
  end

  def users
    self.link(:id=>/ExternalLink/, :text=>"Users").click
    #UsersIndex.new @browser  TODO: Make this class
  end

  def data_partners
    # TODO
  end

  def misc_tab
    self.link(:text=>"Misc").click
    self.div(:class=>"box").wait_until_present
    Misc.new @browser
  end

  def networks
    self.link(:text=>"Networks").click
    NetworksIndex.new @browser
  end

  def log_out
    self.link(:text=>"Log Out").click
    LoginPage.new @browser
  end
  alias logout log_out

end

module LeftMenuBar

  include PageObject

  # TODO - Add all navigation links here.
  def accounts_index
    self.link(:text=>"Accounts Index").click
    default_fido_wait
    AccountsIndex.new @browser
  end

  def sites_index
    self.link(:text=>"Sites Index").click
    self.link(:id=>"ExternalLink_32").wait_until_present
    SitesIndex.new @browser
  end

  #misc_index
  #ad_tags_index
  #users_index

  def site_home
    self.link(:text=>"Site Home").click
    self.link(:text=>"Privacy Policy").wait_until_present
    Site.new @browser
  end

  def account_home_page
    self.div(:id=>"col1").link(:text=>"Account Home").click
    self.link(:text=>"Add/Edit Brandings").wait_until_present
    Account.new @browser
  end

  #third_party_tag_index
  #data_partner_index
  #data_partner_settings
  #help_faq
  #email_us
  #terms_and_conditions
  #privacy_policy
  #edit_profile
  #vtc_manager
  def io_accountability
    self.link(:text=>"I/O Accountability").click
    IOAccountability.new @browser
  end
  #transaction_history
  #audit
  def keyword_matching
    self.link(:text=>"Keyword Matching").click
    self.button(:class=>"controlButton submitKeywords").wait_until_present
    KeywordMatching.new @browser
  end
  #manage_user_profile
  #transactions
  #overview

  def campaign_home
    self.link(:text=>"Campaign Home").click
    Campaign.new @browser
  end
  #campaign_dqs
  #campaign_pricing
  #dynamic_manager
  #creative_home
  #multiple_assets
  #preview_creative
  #creative_keywords
  #add_account
  #add_campaign

  def add_creative
    self.link(:text=>"Add Creative").click
    Creative.new @browser
  end

  #add_site
  #add_network_tag
  #add_network
  #add_data_partner
  #add_third_party_tag
  #all_users
  #administrators
  #employees
  #ess_clients
  #create_user
  #data_partner_settings
  def cookie_analysis
    self.link(:text=>"Cookie Analysis").click
    self.div(:class=>"box").wait_until_present
    CookieAnalysis.new @browser
  end
  #goal_setting

  def pup_list
    self.link(:text=>"PUP List").click
    PUPList.new @browser
  end

  #pup_list_report
  #auditor



end

module NavigationalAids  # SOME OF These need to be deprecated over time...

  include PageObject
  include LeftMenuBar
  include HeaderBar

  # This method is designed to be usable from any page,
  # so the site name link does not have to be on the current page.
  # Note, however, that it assumes the Site is currently Active.
  def open_site(site_name)
    self.sites_index
    begin
      self.link(:text=>site_name[0].upcase).click
    rescue
      self.link(:text=>"9").click
    end
    self.link(:text=>site_name).click
    default_fido_wait
    Site.new @browser
  end

  def open_account(account_name)
    self.accounts_index
    begin
      self.link(:text=>account_name[0].upcase).click
    rescue
      self.link(:text=>"9").click
    end
    self.link(:text=>account_name).click
    default_fido_wait
    Account.new @browser
  end

  def open_campaign(campaign_name)
    self.link(:text=>campaign_name).click
    default_fido_wait
    Campaign.new @browser
  end

  def open_creative(creative_name)
    self.link(:text=>creative_name).click
    default_fido_wait
    Creative.new @browser
  end

  def open_network(network_name)
    networks
    self.link(:text=>network_name[0].upcase).click
    self.link(:text=>network_name).click
    self.button(:id=>"Submit_1").wait_until_present
    Network.new @browser
  end

  def open_user(user_name)
    users
    self.link(:text=>user_name[0].upcase).click
    self.link(:text=>user_name).click
    User.new @browser
  end

end

module CrawlerMethods # TODO improve/deprecate some or all of this!

  def nav(text)
    @browser.link(:text, text).wait_until_present
    @browser.link(:text, text).flash
    @browser.link(:text, text).click
  end

  def submit
    begin
      @browser.button(:id, "Submit").click
    rescue Watir::Exception::UnknownObjectException
      @browser.button(:id, "Submit_0").click
    end
  end
  def test(text)
    puts "~~PAGE~~ #{@browser.title}"
    if @browser.text.include?(text)
      puts ">>> Test of '#{text}' passed."
    else
      puts ""
      puts "=============="
      puts "Test of '#{text}' failed!"
      puts "=============="
      puts ""
    end
  end

  def ascii_test(field)
    if @browser.text_field(:id, field).value.is_ascii?
      puts "#{field} is ascii"
    else
      puts "#{field} is not ascii"
    end
  end

  def check_text_field(field_id, failure_text, success_text)
    original_value = @browser.text_field(:id, field_id).value
    puts field_id
    @browser.text_field(:id, field_id).value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")

    submit

    ascii_test(field_id)
    test(failure_text)

    @browser.text_field(:id, field_id).value = random_string(32)
    submit

    test(failure_text)

    @browser.text_field(:id, field_id).value = random_alphanums(32)
    submit
    test(success_text)
    @browser.text_field(:id, field_id).value = original_value
    submit

  end

  def check_URL_field(field_id)
    puts field_id
    original_value = @browser.text_field(:id, field_id).value
    @browser.text_field(:id, field_id).value = random_non_ASCII_string(10, "") + random_ASCII_string(32, "")
    submit

    ascii_test(field_id)

    test("Specified URL is invalid.")

    @browser.text_field(:id, field_id).value = "http://www." + random_non_ASCII_string(8, "") + random_ASCII_string(8, "") + ".com"
    submit

    test("Specified URL is invalid.")

    @browser.text_field(:id, field_id).value = "http://www." + random_alphanums_plus(32) + ".com"
    submit

    test("Specified URL is invalid.")

    @browser.text_field(:id, field_id).value = "http://www." + random_alphanums(32) + ".com"
    submit

    test("successfully updated.")
    @browser.text_field(:id, field_id).value = original_value
    submit
  end

  def check_num_field(field_id)
    puts field_id
    original_value = @browser.text_field(:id, field_id).value
    @browser.text_field(:id, field_id).value = random_non_ASCII_string(5, "") + random_ASCII_string(5, "")
    submit

    test("**")

    @browser.text_field(:id, field_id).value = random_alphanums_plus(10)
    submit

    test("**")

    @browser.text_field(:id, field_id).value = random_numbers(7) + "." + random_numbers(2)
    submit

    test("**")

    reasonable_number = "0." + random_numbers(2)

    @browser.text_field(:id, field_id).value = reasonable_number
    submit

    if @browser.text.include?("**")
      puts ""
      puts "=============="
      puts "#{field_id} Reasonable number (#{reasonable_number}) rejected!"
      puts "=============="
      puts ""
    else
      puts ">>>#{field_id} passed"
    end
    @browser.text_field(:id, field_id).value = original_value
    submit
  end


end