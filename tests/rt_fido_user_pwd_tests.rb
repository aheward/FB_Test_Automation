#!/usr/bin/env ruby
# coding: UTF-8
TEST_TYPE = :rt
require '../config/fido_env'

# Existing User
nav("Users")
@browser.link(:text, @fido.test_data['test_user']).click

1.upto(4) do | x |
  original_value = @browser.text_field(:id, "TextField_#{x}").value
  @browser.text_field(:id, "TextField_#{x}").value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
  submit

  ascii_test("TextField_#{x}")
  @browser.text_field(:id, "TextField_#{x}").value=original_value
  submit
end

@browser.text_field(:id, "TextField_4").value = "909-233-0909"

# Name test
# Shouldn't the Name field be read-only?
if @browser.text_field(:id, "TextField_0").disabled? == true
  puts ">>> Name is read-only"
else
  puts ""
  puts "=============="
  puts "The Name field is not read-only!"
  puts "=============="
  puts ""
end

# Password

def logout
  nav("Log Out")
end

username = @browser.text_field(:id, "TextField_0").value
pword = random_non_ASCII_string(16, "")
puts pword

@browser.text_field(:id, "password").value = pword
submit

test("Password not changed or set.")

pword = random_ASCII_string(16, "")
puts pword

@browser.text_field(:id, "password").value = pword
submit

test("Password not changed or set.")

pword = random_string(16, "")
puts pword

@browser.text_field(:id, "password").value = pword
submit
logout
accounts_index = login_page.log_in(username, pword)
logout
accounts_index = login_page.log_in(fido.user_name, fido.password)

@browser.close