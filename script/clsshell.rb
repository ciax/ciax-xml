#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libalias"
require "libview"
require "libclssrv"
require "libshell"

cls=ARGV.shift
opt='alsp'
if (/^-/ === cls)
  opt=cls.delete('-')
  cls=ARGV.shift
end
id=ARGV.shift
iocmd=ARGV.shift
begin
  cobj=ClsSrv.new(id,cls,iocmd)
  odb=ObjDb.new(id,cls)
  al=Alias.new(odb)
  view=View.new(cobj.stat,odb).opt(opt)
rescue SelectID
  abort "Usage: clsshell (-alsp) [cls] [id] [iocmd]\n#{$!}"
end
cobj.session{|stm|
  if stm.empty?
    view.upd
  else
    cobj.dispatch(al.alias(stm))
  end
}
