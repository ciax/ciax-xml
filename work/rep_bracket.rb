#!/usr/bin/env ruby
# Replace bracket of method: "method_name(...)" -> "method_name{...}"
# alias repb
abort('Usage: rep-bracket [method_name]') if ARGV.empty?
token = ARGV.shift
readlines.each do |line|
  puts line.gsub(/#{token}\((.+)\)/, "#{token}{\\1}")
end
