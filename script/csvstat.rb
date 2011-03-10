#!/usr/bin/ruby
require "json"
require "libcxcsv"

stat=JSON.load(gets(nil))
cx=CxCsv.new stat["id"]
puts cx.mkres(stat)
