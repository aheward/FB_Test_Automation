module Randomizers

  def random_non_ASCII_string(length=10, s="") # FIDO should reject these strings
    length.enum_for(:times).inject(s) do |result, index|
      s << rand(1024) + 256
    end
  end

  def random_ASCII_string(length=10, s="")  # WARNING: Uses all possible printable EXTENDED ASCII chars!
    length.enum_for(:times).inject(s) { s << rand(221) + 33 }  # Use this when you're trying to be mean to the code.
  end

  def random_string(length=10, s="")  # A "friendlier" version of the above.  Doesn't use high ASCII.
    length.enum_for(:times).inject(s) { s << rand(93) + 33 }
  end

  def random_alphanums_plus(length=10)  # A "friendlier" version of the above. Makes JSSH-compatible strings.
                                        # Note that this character set is larger than what is allowed for OIDs. OIDs allow only the following: [-._@#,0-9A-Za-z]
                                        # Characters outside that set will be dropped from the string.
    chars = %w{a b c d e f g h j k m n p q r s t u v w x y z A B C D E F G H J K L M N P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 ` ~ ! @ # $ % ^ & * ( ) _ + - = | [ ] ; : < > , . /}
    (0...length).map { chars[rand(chars.size)]}.join
  end

  def random_nicelink(length=10)  # A "friendlier" version of the above. No characters need to be escaped for valid URLs.
                                  # Uses no Reserved or "Unsafe" characters--except the @ sign--and the plus sign,.
                                  # Also avoids the comma, which screws up the initial pixel link if it's in the category value.
    chars = %w{a b c d e f g h j k m n p q r s t u v w x y z A B C D E F G H J K L M N P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 @ _ + - .}
    (0...length).map { chars[rand(chars.size)]}.join
  end

  def random_alphanums(length=10, s="")  # A "friendlier" version of the above.  Only uses letters and numbers.
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
    length.times { s << chars[rand(chars.size)] }
    s.to_s
  end

  def random_letters(length=10, s="")  # Only uses letters.
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'
    length.times { s << chars[rand(chars.size)] }
    s.to_s
  end

  def random_numbers(length=10, s="")  # Only uses numbers.
    length.enum_for(:times).inject(s) { s << rand(10) + 48 }
  end

end # Randomizers