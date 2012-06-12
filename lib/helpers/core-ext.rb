module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

class Float
  suppress_warnings { EPSILON =1e-1 }

  def ==(x)
    (self-x).abs < EPSILON
  end

  def equals?(x,tolerance=EPSILON)
    (self-x).abs < tolerance
  end

end

class String

  def is_ascii?
    self.each_byte {|c| return false if c>=128}
    true
  end

end