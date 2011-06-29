#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libserver"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
rescue SelectID
  abort "Usage: clsserver [cls] [id] [port] [iocmd]\n#{$!}"
end
Server.new(port){|line|
  case line
  when ''
    cobj
  when /stop/
    cobj.interrupt
  else
    cobj.dispatch(line.split(" "))
  end
}
