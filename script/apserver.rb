#!/usr/bin/ruby
require "json"
require "libclssrv"
require "libascpck"

cls,id,iocmd,port=ARGV
begin
  cobj=ClsSrv.new(id,cls,iocmd)
  ap=AscPck.new(id,cobj.stat)
rescue SelectID
  abort "Usage: apserver [cls] [id] [iocmd] [port]\n#{$!}"
end
cobj.session(port,["\n",">"]){|line|
  cobj.dispatch(line){|s| ap.issue(s)}
  ap.upd
}
