class BlacklistedSites
  attr_accessor :sites
  def initialize
    @blacklist = YAML.load_file("#{File.dirname(__FILE__)}/blacklisted_sites.yml")
    @sites = @blacklist["sites"]
  end
end