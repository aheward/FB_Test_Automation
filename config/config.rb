require 'yaml'

# Class that configures all test variables
class FBConfig

  # Gets all the necessary test variables...

  @@config = YAML.load_file("#{File.dirname(__FILE__)}/config.yml")
  
  def initialize

    @server = @@config['server']
    @data_wiki = @@config['confluence_test_data']

    # This grabs the machine's Hosts file to ensure
    # testing is being done with the right IP configuration...
    f = File.open(%q|C:\Windows\System32\drivers\etc\hosts|, "r")
    @text = f.read

    raise FBErrorMessages::Settings.config_prod_reg_test if TEST_TYPE != :prod && @server=='prod'

    def check_hosts
      raise FBErrorMessages::Settings.hosts_is_prod if @text =~ /#{@@config['prod_imp']}.*clk.fetchback.com/
    end

    fb = ".fetchback.com"
    h = "http://"
    test_link = h + @server + fb
    qa_fido_pix1 = h + @@config['qa-fido_pixel1']
    qa_fido_pix2 = h + @@config['qa-fido_pixel2']
    qa_fido_imp1 = h + @@config['qa-fido_imp1']
    qa_fido_imp2 = h + @@config['qa-fido_imp2']
    prod_imp = @@config['prod_imp']

    case(@server)
       when 'prod'
         info = {:link=>h + "www#{fb}",
          :ip=>prod_imp,
          :imp1 =>h + prod_imp,
          :pix1 =>h + @@config['prod_pixel'],
          :imp2 =>"",
          :pix2=>""}
       when 'qa-fido'
         check_hosts
         info = {:link=>h + "qa-fido#{fb}",
                 :ip=>@@config['qa_imp'],
                 :pix1=>qa_fido_pix1,
                 :imp1=>qa_fido_imp1,
                 :pix2=>qa_fido_pix2,
                 :imp2=>qa_fido_imp2}
       else
         check_hosts
         info = {:link=>test_link,
                 :ip=>@@config["#{@server}_ip"],
                 :pix1=>test_link,
                 :imp1=>test_link,
                 :pix2=>test_link,
                 :imp2=>test_link}
    end

    $test_site = info[:link]
    $test_site_ip = info[:ip]
    $pixel_log =       info[:pix1] + @@config['pixel']
    $imp_log =         info[:imp1] + @@config['imp']
    $impvar_log =      info[:imp1] + @@config['impvar']
    $conversion_log =  info[:pix1] + @@config['conversion']
    $affiliate_log =   info[:pix1] + @@config['affiliate']
    $product_log =     info[:pix1] + @@config['product']
    $proxy_log =       info[:pix1] + @@config['proxy']
    $pixel_log1 =      info[:pix2] + @@config['pixel']
    $imp_log1 =        info[:imp2] + @@config['imp']
    $impvar_log1 =     info[:imp2] + @@config['impvar']
    $conversion_log1 = info[:pix2] + @@config['conversion']
    $affiliate_log1 =  info[:pix2] + @@config['affiliate']
    $product_log1 =    info[:pix2] + @@config['product']
    $proxy_log1 =      info[:pix2] + @@config['proxy']

    def error(hosts_file)
      puts "\nYour test site doesn't match your Hosts file!   Aborting...\n\n"
      puts "\tTest site set in your config.yml:\n\t\t#{$test_site}"
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
    end

    # Makes sure the hosts file is pointing at the machine
    # it needs to be.
    raise error(@text) unless @text =~ /#{$test_site_ip}.*clk.fetchback.com/

    $local_ip = @@config['your_ip']
    $fido_username = @@config['fido_username']
    $fido_password = @@config['fido_password']
    $confluence_username = @@config['confluence_username']
    $confluence_password = @@config['confluence_password']
    $offset = @@config['offset'].to_i
    $imp_seconds = @@config['imp_viewing_time']
    $extra_imp_count = @@config['extra_imps']
    $browser = @@config['browser']

    if DEBUG > 1
      puts "$test_site: " + $test_site
      puts "$test_site_ip: " + $test_site_ip
      puts "$pixel_log: " + $pixel_log
      puts "$imp_log: " + $imp_log
      puts "$impvar_log: " + $impvar_log
      puts "$conversion_log: " + $conversion_log
      puts "$affiliate_log: " + $affiliate_log
      puts "$product_log: " + $product_log
      puts "$proxy_log: " + $proxy_log
      puts "\nThese log URLs only need to be right if you're testing qa-fido..."
      puts "$pixel_log1: " + $pixel_log1
      puts "$imp_log1: " + $imp_log1
      puts "$impvar_log1: " + $impvar_log1
      puts "$conversion_log1: " + $conversion_log1
      puts "$affiliate_log1: " + $affiliate_log1
      puts "$product_log1: " + $product_log1
      puts "$proxy_log1: " + $proxy_log1
      puts "\n$local_ip: " + $local_ip
      puts "$fido_username: " + $fido_username
      puts "$fido_password: " + $fido_password
      puts "$confluence_username: " + $confluence_username
      puts "$confluence_password: " + $confluence_password
      puts "$offset: " + $offset.to_s
      puts "$imp_seconds: " + $imp_seconds.to_s
      puts "$extra_imp_count: " + $extra_imp_count.to_s
      puts "$browser: " + $browser.to_s
    end

  end # initialize

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