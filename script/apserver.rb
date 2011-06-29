#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libascpck"

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
port=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
  ap=AscPck.new(id,cobj.stat)
rescue SelectID
  abort "Usage: apserver [cls] [id] [iocmd] [port]\n#{$!}"
end
cobj.session(port,['>']){|stm|
  case stm[0]
  when nil,/stat/
  when /stop/
    cobj.interrupt
  else
    ap.issue
    cobj.dispatch(stm)
  end
  ap.upd
}
