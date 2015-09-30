#!/usr/bin/ruby
#alias repb
abort("Usage: rep-bracket [method_name]") unless ARGV.size > 0 
token=ARGV.shift
readlines.each{|line|
  puts line.gsub(/#{token}\((.+)\)/,"#{token}{\\1}")
}
