#!/usr/bin/ruby
abort "Usage: log2b64 (files)" if STDIN.tty? && ARGV.size < 1
readlines.each{|line|
  next if line.to_s.empty?
  tm,cid,str=line.split("\t")
  next if str.to_s.empty?
  if /^".*"$/ =~ str
    str=[eval(str)].pack("m").split("\n") * ''
  end
  puts [tm,cid,str].join("\t")
}
