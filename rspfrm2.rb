#!/usr/bin/ruby
require "libdevstat"

warn "Usage: rspfrm [dev] [cmd] < file" if ARGV.size < 1

e=DevStat.new(ARGV.shift)
e.setcmd(ARGV.shift)
e.getrsp{gets(nil)}
p e.rspfrm
