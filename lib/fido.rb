require 'page-object'
require 'fido/core-ext'
require 'fido/gem_ext'
require 'fido/fb-modules'
require 'fido/page_classes'

class Fido

  attr_reader :browser, :user_name, :password, :test_data

  def initialize(test_type)
    @config = YAML.load_file("../config/config.yml")
    @server = @config['server']

    if @server == 'prod' && test_type == :rt
      puts "This script is for testing dev boxes. Change your config to point away from production."
      exit
    elsif @server != 'prod' && test_type == 'prod'
      puts "This script is for testing production. Fix your config file."
      exit
    end

    @user_name = @config['fido_username']
    @password = @config['fido_password']
    @browser = Watir::Browser.new @config['browser']
    @browser.window.resize_to(1400,900)

    case(@server)
      when 'prod'
        @browser.goto "www.fetchback.com/fido"
      when 'qa-fido'
        @browser.goto "qa-fido.fetchback.com/fido"
      else
        @browser.goto "#{@server}.fetchback.com/fido"
    end

    @test_data = YAML.load_file("../lib/fido_test_data.yml")

  end

  def page
    LoginPage.new @browser
  end

end