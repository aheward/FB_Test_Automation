#!/usr/bin/env ruby
# coding: UTF-8

# =========================
# Index page crawls...
# =========================
TEST_TYPE = :rt
require '../config/fido_env'

nav("Sites Index")

('A'..'Z').each do |letter|
  puts "Site: #{letter}"
  nav(letter)
  test("Specialist")
  @browser.select(:id, "PropertySelection").select("Inactive")
  test("Cash Balance")
  @browser.select(:id, "PropertySelection").select("Active")
end

nav("Account Home")

('A'..'Z').each do |letter|
  puts "Account: #{letter}"
  nav(letter)
  @browser.select(:id, "PropertySelection").select("Inactive")
end

nav("Users")

('A'..'Z').each do |letter|
  puts "Users: #{letter}"
  nav(letter)
  test("Telephone")
end

nav("Networks")

('A'..'Z').each do |letter|
  puts "Network: #{letter}"
  nav(letter)
  test("UserName")
  @browser.select(:id, "PropertySelection").select("Inactive")
  test("Email")
  @browser.select(:id, "PropertySelection").select("Active")
end

@accounts_index.logout
test("User:")

@browser.close