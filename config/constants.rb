module FetchBackConstants

  # Merit window test values, expressed in seconds...
  MERIT_OFFSETS = %w{2592000 2591900 691200 604800 604700 345555 259200 259100 86400 86240 20000 15000 10000}

  # The three basic types of conversions...
  CONVERSIONS = %w{dtc vtc ctc}

  # Fetchback's browser cookies
  COOKIES = %w{uid kwd uat bpd cmp clk afl sit cre scg apd eng ppd act opt}

  # The sites.db database...
  SITES_DB = SQLite3::Database.open( "../lib/sites.db" )

  # Conversion windows (units here are days)
  WINDOWS = %w{90 60 45 21 14 7 5}

  # Direct/Organic conversion offsets
  CONVERSION_OFFSETS = [ 7150, 7200 ]

  # Prefix for imp links...
  IMP_SERVER = "http://imp.fetchback.com/serve/fb/"

  # Prefix for pixel links...
  PIXEL_SERVER = "http://pixel.fetchback.com/serve/fb/"

  # The link text that goes after 'clicktrack=' in a click link...
  CLICKTRACK = "http://fido.fetchback.com/clicktrack.php%3F%2C"

  # An empty page on the fetchback domain. This
  # is necessary so that the scripts can easily
  # retrieve the fetchback cookies...
  DUMMY_PAGE = "http://pixel.fetchback.com/timeout.html"

  # This is the name of the QA test 'cluster'. Please see the
  # 'get_log' method in the Logs module for why this is needed.
  CLUSTER = "qa-fido"

end