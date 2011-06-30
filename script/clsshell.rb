#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libalias"
require "libview"
require "libclssrv"
require "libshell"

opt=ARGV.shift
if (/^-/ === opt)
  cls=ARGV.shift
else
  cls=opt
  opt='alsp'
end
id=ARGV.shift
iocmd=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
  odb=ObjDb.new(id,cls)
  al=Alias.new(odb)
  view=View.new(cobj.stat,odb).add(opt)
rescue SelectID
  abort "Usage: clsshell (-alsp) [cls] [id] [iocmd]\n#{$!}"
end
cobj.session{|line|
  cobj.dispatch(line){|stm| al.alias(stm)}||view.upd
}
