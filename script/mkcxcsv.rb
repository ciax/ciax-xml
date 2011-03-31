#!/usr/bin/ruby
require "json"
require "libcxcsv"
#abort "Usage: mkcxcsv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
cx=CxCsv.new(stat['id'])
puts cx.mkres(stat)
