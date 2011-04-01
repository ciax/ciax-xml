#!/usr/bin/ruby
require "json"
require "libascpck"
abort "Usage: ascpck [file" if STDIN.tty? && ARGV.size < 1
begin
  stat=JSON.load(gets(nil))
  ap=AscPck.new(stat['id'])
  print ap.convert(stat)
rescue
  abort $!.to_s
end
