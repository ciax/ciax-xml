#!/usr/bin/ruby
# Log viewer
# For stream log version 6 or later
require "json"

abort "Usage: json_logview json_log" if STDIN.tty? && ARGV.size < 1
readlines.each{|line|
  next if line.to_s.empty?
  ary=[]
  JSON.load(line.chomp).each{|k,v|
    case k
    when 'time'
      ary << Time.at(v.to_f/1000).to_s
    when 'base64'
      ary << v.unpack("m").first.inspect
    else
      ary << "#{k}=#{v}"
    end
  }
  puts ary.join("\t")
}
