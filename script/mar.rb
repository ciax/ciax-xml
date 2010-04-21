#!/usr/bin/ruby
Marshal.load(gets(nil)).sort.each do |e|
  p e
end
