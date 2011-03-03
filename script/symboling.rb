#!/usr/bin/ruby
require "json"

#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  require "libfrmsym"
  dv=FrmSym.new(type)
elsif type=stat['class']
  require "libclssym"
  dv=ClsSym.new(type)
end
puts JSON.dump(dv.convert(stat))
