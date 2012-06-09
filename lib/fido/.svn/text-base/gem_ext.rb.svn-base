module PageObject

  def method_missing(sym, *args, &block)
    @browser.send sym, *args, &block
  end

  def default_fido_wait
    self.link(:text=>"Privacy Policy").wait_until_present
  end

end