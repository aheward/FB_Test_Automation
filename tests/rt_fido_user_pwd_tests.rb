#!/usr/bin/env ruby
# coding: UTF-8
TEST_TYPE = :rt
require '../config/fido_env'

# Existing User
@user = @accounts_index.open_user(@fido.test_data['test_user'])

["first_name", "last_name", "email", "phone"].each_with_index do | field, index |
  original_value = @user.send(field)

  @user.send("#{field}_element").value = random_ASCII_string(16, "") + random_non_ASCII_string(16, "")
  submit

  ascii_test("TextField_#{index+1}")
  @user.send("#{field}_element").value=original_value
  submit
end

# Name test
# Shouldn't the Name field be read-only?
if @user.username_element.enabled?
  puts ""
  puts "=============="
  puts "The Name field is not read-only!"
  puts "=============="
  puts ""
else
  puts ">>> Name is read-only"
end

# Password

username = @user.username
pword = random_non_ASCII_string(16, "")
puts pword

@user.password=pword
submit

test("Password not changed or set.")

pword = random_ASCII_string(16, "â") # Note, this is seeded with the â to ensure that the string will contain at least one bad character.
puts pword

@user.password=pword
submit

test("Password not changed or set.")

pword = random_string(16, "")
puts pword

@user.password=pword
submit
login_page = @user.logout
accounts_index = login_page.log_in(username, pword)

if accounts_index.logo?
  @browser.close
else
  puts "Please check that the user logged in with the new password. Something is broken."
end

