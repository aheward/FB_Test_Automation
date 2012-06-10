
module PageNavigation
  def visit page_class, &block
    on page_class, true, &block
  end

  def on page_class, visit=false, &block
    page = page_class.new @browser, visit
    block.call page if block
    page
  end
end

class GenericBasePage

  def initialize browser, visit = false
    @browser = browser
    goto if visit
  end

  def method_missing sym, *args, &block
    @browser.send sym, *args, &block
  end

  def self.page_url url
    define_method 'goto' do
      @browser.goto url
    end
  end

  class << self
    alias :direct_url :page_url
  end

  def self.element element_name
    define_method element_name.to_s do
      yield self
    end
  end

  class << self
    alias :value :element
    alias :action :element
  end

end
