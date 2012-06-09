=begin

This simple script is designed to compare the live version of the CSV Reports
with the version generated on the test site and report any differences.

Obviously you should be sure to run the exact same CSV reports on both sites
in order that the comparison make sense.

The files should be given the names:
live.csv
test.csv

...and placed in the same file directory as this script

The output of this script is any lines in the files that don't match.

In other words, no output means good output.

=end

array1 = []
array2 = []

File.open("live.csv").each do | line |
	array1 << line
end

File.open("test.csv").each do | line |
	array2 << line
end

puts array2 - array1
puts ""
puts array1 - array2