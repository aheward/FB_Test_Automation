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
  CONVERSION_OFFSETS = [ 7175, 7200 ]

  # Prefix for pixel links...
  PIXEL_SERVER = "http://pixel.fetchback.com/serve/fb/"

end