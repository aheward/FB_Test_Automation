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

    if TEST_TYPE != :prod && @server=='prod'
      puts "Your config file is set to test production."
      puts "However, you appear to be running a script made for"
      puts "regression testing. Please fix this."
      exit
    end

    def check_hosts
      if @text =~ /#{@@config['prod_imp']}.*clk.fetchback.com/
        puts "You must point your Hosts file away from production!"
        puts "This script is aborted until you fix this."
        exit
      end
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
          :pix1 =>@@config['prod_pixel'],
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
      exit
    end

    # Makes sure the hosts file is pointing at the machine
    # it needs to be.
    unless @text =~ /#{$test_site_ip}.*clk.fetchback.com/
      error(@text)
    end

    $local_ip = open("http://myip.dk") { |f| /([0-9]{1,3}\.){3}[0-9]{1,3}/.match(f.read)[0] }
    $fido_username = @@config['fido_username']
    $fido_password = @@config['fido_password']
    $confluence_username = @@config['confluence_username']
    $confluence_password = @@config['confluence_password']
    $offset = @@config['offset'].to_i
    $imp_seconds = @@config['imp_viewing_time']
    $extra_imp_count = @@config['extra_imps']

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