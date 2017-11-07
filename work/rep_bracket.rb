#!/usr/bin/ruby
# Replace bracket of method: "method_name(...)" -> "method_name{...}"
#alias repb
abort('Usage: rep-bracket [method_name]') unless ARGV.size > 0
token = ARGV.shift
readlines.each do|line|
  puts line.gsub(/#{token}\((.+)\)/, "#{token}{\\1}")
end
