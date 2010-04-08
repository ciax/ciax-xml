#!/usr/bin/ruby
require "libdevstat"

warn "Usage: rspfrm [dev] [cmd] < file" if ARGV.size < 1

e=DevStat.new(ARGV.shift,ARGV.shift)
p e.rspfrm{gets(nil)}
