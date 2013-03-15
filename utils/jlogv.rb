#!/usr/bin/ruby
# For stream log version 6 or later
require "libmsg"
require "json"

abort "Usage: jlogv json_log" if STDIN.tty? && ARGV.size < 1
readlines.each{|line|
  next if line.to_s.empty?
  ary=[]
  JSON.load(line.chomp).each{|k,v|
    case k
    when 'time'
      ary << Time.at(v.to_f).to_s
    when 'base64'
      ary << v.unpack("m").first
    else
      ary << "#{k}=#{v}"
    end
  }
  puts ary.join("\t")
}
