
class CookieEditor < GenericBasePage

  page_url(FBConfig.get :cookie)

  element(:site_id) { |b| b.text_field id: "siteId" }
  element(:campaign_id) { |b| b.text_field id: "campaignId" }
  element(:creative_id) { |b| b.text_field id: "creativeId" }
  element(:ad_tag_id) { |b| b.text_field id: "networkAdTagId" }
  element(:offset) { |b| b.text_field id: "offset" }
  element(:uid) { |b| b.text_field id: "uid" }
  element(:otc) { |b| b.button id: "otc" }
  element(:merit) { |b| b.button id: "merit" }
  element(:control) { |b| b.button id: "control" }
  element(:show_cookies) { |b| b.button value: "Show Cookies" }
  element(:debug) { |b| b.checkbox name: "debug" }

  def set_control_cookie(percent)
    uid.set percent.to_s
    control.click
  end

  def set_otc_offset(site_id_value, campaign_id_value, offset_value)
    site_id.set site_id_value
    campaign_id.set campaign_id_value
    offset.set offset_value.to_s
    otc.click
  end

  def set_merit_offset(ad_tag_id_value, creative_id_value, offset_value)
    ad_tag_id.set ad_tag_id_value
    creative_id.set creative_id_value
    offset.set offset_value
    merit.click
  end

end

# This module creates methods that allow you to get access
# to a given cookie's info by
# invoking it as a method on the browser object itself.
#
# @example
#   @browser.uid[:value]
#   => "1_1338645110_1338645060288:8431891593843600"
#
# If ever a new cookie is added, just add the new cookie's name
# to the COOKIES list in the Constants module and it will instantly become
# available as a method.
module FetchBackCookies

  include FetchBackConstants

  COOKIES.each do |cookie|
    define_method(cookie) { keep_if(cookie) }
  end

  # Returns the UID of the uid cookie, without
  # the version and timestamp prefix. Use with the
  # browser object.
  def unique_identifier
    self.uid[:value][/(?<=_)\d+:\d+$/]
  end

  private

  def keep_if(name)
    array = self.cookies.to_a.keep_if { |hash| hash[:name]==name }
    array[0]
  end

end