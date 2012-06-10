require 'yaml'

# Class that configures all test variables
class FBConfig

  attr_reader( :local_ip, :fido_username, :fido_password,
               :confluence_username, :confluence_password, :offset,
               :test_site, :pixel_log, :imp_log, :impvar_log, :conversion_log,
               :affiliate_log, :product_log, :proxy_log, :pixel_log1, :imp_log1,
               :impvar_log1, :conversion_log1, :affiliate_log1, :product_log1,
               :proxy_log1, :test_site_ip, :data_wiki,
               :imp_seconds, :extra_imp_count
  )

  # Gets all the necessary test variables...
  @@config = YAML.load_file("#{File.dirname(__FILE__)}/config.yml")

  def initialize

    @server = @@config['server']
    #@cookie_editor = @@config['cookie']
    @data_wiki = @@config['confluence_test_data']

    # This grabs the machine's Hosts file to ensure
    # testing is being done with the right IP configuration...
    f = File.open(%q|C:\Windows\System32\drivers\etc\hosts|, "r")
    @text = f.read

    def check_if_testing_production
      if @server=='prod'
        puts "Your config file is set to test production."
        puts "However, you appear to be running a script made for"
        puts "regression testing. Please fix this."
        exit
      end
    end

    unless TEST_TYPE == :prod
      check_if_testing_production
    end

    def check_hosts
      if @text =~ /#{@@config['prod_imp']}.*clk.fetchback.com/
        puts "You must point your Hosts file away from production!"
        puts "This script is aborted until you fix this."
        exit
      end
    end

    case(@server)
      when 'prod'
        @test_site = "www.fetchback.com"
        @test_site_ip = @@config['prod_imp']
        @pixel_log = "http://#{@@config['prod_pixel']}#{@@config['pixel']}"
        @imp_log = "http://#{@@config['prod_imp']}#{@@config['imp']}"
        @impvar_log = "http://#{@@config['prod_imp']}#{@@config['impvar']}"
        @conversion_log = "http://#{@@config['prod_pixel']}#{@@config['conversion']}"
        @affiliate_log = "http://#{@@config['prod_pixel']}#{@@config['affiliate']}"
        @product_log = "http://#{@@config['prod_pixel']}#{@@config['product']}"
        @proxy_log = "http://#{@@config['prod_pixel']}#{@@config['proxy']}"
        @pixel_log1 = "http://"
        @imp_log1 = "http://"
        @impvar_log1 = "http://"
        @conversion_log1 = "http://"
        @affiliate_log1 = "http://"
        @product_log1 = "http://"
        @proxy_log1 = "http://"
      when 'qa-fido'
        check_hosts
        @test_site = "qa-fido.fetchback.com"
        @test_site_ip = @@config['qa_imp']
        @pixel_log = "http://#{@@config['qa-fido_pixel1']}#{@@config['pixel']}"
        @imp_log = "http://#{@@config['qa-fido_imp1']}#{@@config['imp']}"
        @impvar_log = "http://#{@@config['qa-fido_imp1']}#{@@config['impvar']}"
        @conversion_log = "http://#{@@config['qa-fido_pixel1']}#{@@config['conversion']}"
        @affiliate_log = "http://#{@@config['qa-fido_pixel1']}#{@@config['affiliate']}"
        @product_log = "http://#{@@config['qa-fido_pixel1']}#{@@config['product']}"
        @proxy_log = "http://#{@@config['qa-fido_pixel1']}#{@@config['proxy']}"
        @pixel_log1 = "http://#{@@config['qa-fido_pixel2']}#{@@config['pixel']}"
        @imp_log1 = "http://#{@@config['qa-fido_imp2']}#{@@config['imp']}"
        @impvar_log1 = "http://#{@@config['qa-fido_imp2']}#{@@config['impvar']}"
        @conversion_log1 = "http://#{@@config['qa-fido_pixel2']}#{@@config['conversion']}"
        @affiliate_log1 = "http://#{@@config['qa-fido_pixel2']}#{@@config['affiliate']}"
        @product_log1 = "http://#{@@config['qa-fido_pixel2']}#{@@config['product']}"
        @proxy_log1 = "http://#{@@config['qa-fido_pixel2']}#{@@config['proxy']}"
      else
        check_hosts
        @test_site = "#{@server}.fetchback.com"
        @test_site_ip = @@config["#{@server}_ip"]
        @pixel_log = "http://#{@test_site}#{@@config['pixel']}"
        @imp_log = "http://#{@test_site}#{@@config['imp']}"
        @impvar_log = "http://#{@test_site}#{@@config['impvar']}"
        @conversion_log = "http://#{@test_site}#{@@config['conversion']}"
        @affiliate_log = "http://#{@test_site}#{@@config['affiliate']}"
        @product_log = "http://#{@test_site}#{@@config['product']}"
        @proxy_log = "http://#{@test_site}#{@@config['proxy']}"
        @pixel_log1 = "http://"
        @imp_log1 = "http://"
        @impvar_log1 = "http://"
        @conversion_log1 = "http://"
        @affiliate_log1 = "http://"
        @product_log1 = "http://"
        @proxy_log1 = "http://"
    end

    def error(hosts_file)
      puts "\nYour test site doesn't match your Hosts file!   Aborting...\n\n"
      puts "\tTest site set in your config.yml:\n\t\t#{@test_site}"
      ip = hosts_file[/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=\s+pixel.fetchback)/]
      target = case(ip)
        when @@config['pup_ip']
          "pup"
        when @@config['mutt_ip']
          "mutt"
        when @@config['spike_ip']
          "spike"
        when @@config['cujo_ip']
          "cujo"
        when @@config['spot_ip']
          "spot"
        when @@config['qa_pixel']
            "qa-fido"
        else
          "an unknown host (!!!)"
      end
      puts "\nYour Hosts file appears to be pointing at #{target}.\n\n"
      puts "If that's right then update your config.yml. Otherwise,\nfix Hosts and then flush your DNS.\n\n"
      puts "Here's the contents of your current Hosts file...\n\n"
      puts hosts_file
      exit
    end

    # Makes sure the hosts file is pointing at the machine
    # it needs to be.
    unless @text =~ /#{@test_site_ip}.*clk.fetchback.com/
      error(@text)
    end

    @local_ip = open("http://myip.dk") { |f| /([0-9]{1,3}\.){3}[0-9]{1,3}/.match(f.read)[0] }
    @fido_username = @@config['fido_username']
    @fido_password = @@config['fido_password']
    @confluence_username = @@config['confluence_username']
    @confluence_password = @@config['confluence_password']
    @offset = @@config['offset'].to_i
    @imp_seconds = @@config['imp_viewing_time']
    @extra_imp_count = @@config['extra_imps']

  end # initialize

  # Creates a browser object...
  def browser
    b = Watir::Browser.new @@config['browser']
    b.window.resize_to(1400,900)
    b
  end

  def self.get parent, child=nil
    parent = get_sub_tree @@config, parent
    return child.nil? ? parent : get_sub_tree(parent, child)
  end

  private

  def self.get_sub_tree root, item
    sub_tree = root[item.to_s]
    raise "Could not locate '#{item}' in YAML config: '#{root}'" if sub_tree.nil?
    sub_tree
  end

end # Config