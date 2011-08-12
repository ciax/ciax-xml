#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libserver"

cls,id,iocmd,port=ARGV
begin
  cobj=ClsSrv.new(id,cls,iocmd)
rescue SelectID
  abort "Usage: clsserver [cls] [id] [iocmd] [port]\n#{$!}"
end
cobj.session(port){|line|
  cobj.dispatch(line)||JSON.dump(cobj.stat.to_h)
}
