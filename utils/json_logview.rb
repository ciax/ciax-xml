#!/usr/bin/ruby
# Log viewer
# For stream log version 6 or later
# alias jlv
require 'json'

abort 'Usage: json_logview json_log' if STDIN.tty? && ARGV.size < 1
readlines.each do|line|
  next if line.to_s.empty?
  ary = []
  JSON.parse(line.chomp, symbolize_names: true).each do|k, v|
    case k
    when 'time'
      ary << Time.at(v.to_f / 1000).to_s
    when 'base64'
      data = v.unpack('m').first
      ary << "data=#{data.inspect}(#{data.size})"
    else
      ary << "#{k}=#{v.inspect}"
    end
  end
  puts ary.join("\t")
end
