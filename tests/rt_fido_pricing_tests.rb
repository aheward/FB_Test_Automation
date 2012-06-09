# Pricing model inconsistency tests...
#!/usr/bin/env ruby
# coding: UTF-8

require '../config/fido_env'

@accounts_index.open_account @fido.test_data['test_account']

# Add Site
nav("Add Site")

site = "#{random_alphanums(15)}'#{random_alphanums(16)}"

@browser.text_field(:id, "siteName").value=site
@browser.text_field(:id, "url").set("http://www.cloudzero.com")

@browser.text_field(:id, "CPM").set("3")
@browser.text_field(:id, "CPA").set("3")
@browser.select(:id, "specialistUser").select("House")
submit

test("Only one of [CPA, CPA+Revenue Share, CPC, CPE, CPM, Flat Fee] is allowed to be set or enabled.")
test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "CPM").set("0")
@browser.checkbox(:id, "flatFee").set
submit

test("Only one of [CPA, CPA+Revenue Share, CPC, CPE, CPM, Flat Fee] is allowed to be set or enabled.")
test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "CPA").set("0")
@browser.text_field(:id, "CPM").set("3")
@browser.checkbox(:id, "flatFee").clear
@browser.text_field(:id, "percentRevenueShare").value="0.25"
@browser.checkbox(:id, "revenuePixel").clear
submit

test("Setting a Revenue Share % value requires a failover CPA value amount.")

@browser.text_field(:id, "CPA").set("3")
@browser.text_field(:id, "CPM").set("0")
@browser.text_field(:id, "goalCPC").value="10.0"
submit

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "goalCPC").value="0.0"
@browser.text_field(:id, "CPA").set("0")
@browser.text_field(:id, "targetCPC_ECPM").value="10.00"

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "targetCPC_ECPM").value="0.00"
@browser.text_field(:id, "CPC").set("7")
submit

test("Setting a Revenue Share % value requires a failover CPA value amount.")
test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "CPC").value="0.00"
@browser.text_field(:id, "CPE").value="4.12"
submit

test("Setting a Revenue Share % value requires a failover CPA value amount.")
test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")

@browser.text_field(:id, "maxCPCBidPrice").value="9.34"
@browser.text_field(:id, "CPA").value="5.78"
submit

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")
test("Only one of [CPA, CPA+Revenue Share, CPC, CPE, CPM, Flat Fee] is allowed to be set or enabled.")

@browser.text_field(:id, "CPE").value="0"
@browser.text_field(:id, "maxCPCBidPrice").value="0"
@browser.text_field(:id, "CPA").value="0"
@browser.text_field(:id, "goalCPC").value="9.81"
@browser.text_field(:id, "goalCPA").value="7.42"
submit

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")
test("Only one of [CPA Goal, CPC Goal] is allowed to be set or enabled.")

@browser.text_field(:id, "goalCPC").value="0"
@browser.text_field(:id, "CPA").value="0"
@browser.text_field(:id, "targetCPC_ECPM").value="2.26"
@browser.text_field(:id, "targetCPE_ECPM").value="8.81"
submit

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")
test("Only one of [Target CPC ECPM, Target CPE ECPM] is allowed to be set or enabled.")

@browser.text_field(:id, "targetCPC_ECPM").value="0"
@browser.text_field(:id, "targetCPE_ECPM").value="0"
@browser.text_field(:id, "CPA").value="3.65"
@browser.text_field(:id, "maxCPCBidPrice").value="22.91"
@browser.text_field(:id, "maxCPEBidPrice").value="13.56"
submit

test("An overlap of pricing types, goals and/or targets has been detected. Please verify selections.")
test("successfully")

@browser.close