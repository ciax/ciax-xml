#!/usr/bin/env ruby
# Log viewer
# For stream log version 6 or later
# alias jlv
require 'json'

abort 'Usage: json_logview json_log' if STDIN.tty? && ARGV.empty?
readlines.each do |line|
  next if line.to_s.empty?

  ary = []
  JSON.parse(line.chomp, symbolize_names: true).each do |k, v|
    case k
    when :time
      ary << Time.at(v / 1000, (v % 1000) * 1000).strftime('%Y-%m-%d %T,%L')
    when :base64
      data = v.unpack('m').first
      ary << "data=#{data.inspect}(#{data.size})"
    else
      ary << "#{k}=#{v.inspect}"
    end
  end
  puts ary.join("\t")
end
