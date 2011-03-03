#!/usr/bin/ruby
require "json"

#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  require "libfrmsym"
  sym=FrmSym.new(type)
  res=sym.convert(stat)
elsif type=stat['class']
  require "libclssym"
  sym=ClsSym.new(type)
  res=sym.convert(stat)
end
puts JSON.dump(res)
