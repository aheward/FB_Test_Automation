require 'yaml'

class KeywordURLs

  attr_accessor :by_site, :by_campaign

  def initialize
    data = YAML.load_file("#{File.dirname(__FILE__)}/keyword_urls.yml")

    @by_site = data["Sites"]
    @by_campaign = data["Campaigns"]
  end

end
