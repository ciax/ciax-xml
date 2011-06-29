#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libascpck"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
  ap=AscPck.new(id,cobj.stat)
rescue SelectID
  abort "Usage: apserver [cls] [id] [port] [iocmd]\n#{$!}"
end
if port == '0'
  require "libshell"
  int=Shell
  port=['>']
else
  require "libserver"
  int=Server
end

int.new(port){|line|
  cobj.upd
  case line
  when '',/stat/
    ap.upd
  when /stop/
    cobj.interrupt
  else
    ap.issue
    cobj.dispatch(line.split(' '))
  end
}
