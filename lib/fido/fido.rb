class Fido

  include FidoTamers

  attr_reader :browser, :user_name, :password, :test_data

  def initialize
    @config = YAML.load_file("../config/config.yml")
    @server = @config['server']

    if @server == 'prod' && TEST_TYPE == :rt
      puts "This script is for testing dev boxes. Change your config to point away from production."
      exit
    elsif @server != 'prod' && TEST_TYPE == :prod
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

module FidoTamers

  def fido_log_in(user, pwd)
    # Logs in to Fido with specified user credentials.

    if self.text.include?("Password:")			# If we're on the log in page...
      unless self.text_field(:name, "j_username").value.include?(user)
        self.text_field(:name, "j_username").set(user) # Username and password commands go here
        self.text_field(:name, "j_password").focus
        self.text_field(:name, "j_password").set(pwd)
      end
      self.button(:name, "submit").click		# Logs in to Fido
      sleep(1)
      if self.button(:name, "submit").exist?
        self.button(:name, "submit").click
      end
    end
    self.link(:text=>"Privacy Policy").wait_until_present
    AccountsIndex.new @browser
  end
  alias login fido_log_in
  alias log_in fido_log_in

  def open_fido_site(site)
    # Use this method for navigating to desired site overview pages in Fido.
    # The method assumes you're already logged in to Fido.

    self.link(:text, "Sites Index").wait_until_present
    self.link(:text, "Sites Index").click		# Sites Index
    if site[0] =~ /\d/
      self.link(:text, "9").click
    else
      self.link(:text, site[0].upcase).click
    end
    begin
      self.link(:text, "Terms & Conditions").wait_until_present
      if self.link(:text, site).exist?
        self.link(:text, site).click		# Client link
        return true
      else
        self.link(:text, "All").click
        self.link(:text, "Terms & Conditions").wait_until_present
        self.link(:text, site).click		# Client link
        return true
      end
    rescue Watir::Exception::UnknownObjectException
      puts "#{site} doesn't appear to be Active"
      return false
    end
  end

end