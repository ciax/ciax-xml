#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libserver"

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
port=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
rescue SelectID
  abort "Usage: clsserver [cls] [id] [iocmd] [port]\n#{$!}"
end
cobj.session(port,['>']){|stm|
  case stm[0]
  when nil
    cobj.stat
  when /stop/
    cobj.interrupt
  else
    cobj.dispatch(stm)
  end
}
