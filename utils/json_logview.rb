#!/usr/bin/env ruby
# Log viewer
# For stream log version 6 or later
# You can remove keys by setting EXCLUDE environment with CSV
# alias jlv
require 'json'
abort 'Usage: json_logview json_log' if STDIN.tty? && ARGV.empty?
exary = ENV['EXCLUDE'].to_s.split(',')

ARGF.each do |line|
  next if line.to_s.empty?
  hash = {}
  JSON.parse(line.chomp, symbolize_names: true).each do |k, v|
    case k
    when :time
      hash[:time] = Time.at(v / 1000, (v % 1000) * 1000).strftime('%Y-%m-%d %T,%L')
    when :base64
      data = v.unpack('m').first
      hash[:data] = "#{data.inspect}(#{data.size})"
    else
      hash[k] = v unless exary.include?(k.to_s)
    end
  end
  puts JSON.dump(hash)
end
