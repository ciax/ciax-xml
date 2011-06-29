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
cobj.session(port,['>']){|line|
  line=nil if /stop/ === line
  cobj.dispatch(line)||cobj.stat
}
