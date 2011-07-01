#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libalias"
require "libview"
require "libclssrv"
require "libshell"

opt,arg = ARGV.partition{|s| /^-/ === s}
opt= opt.empty? ? 'alsp' : opt.join('')
cls,id,iocmd=arg

begin
  cobj=ClsSrv.new(id,cls,iocmd)
  odb=ObjDb.new(id,cls)
  al=Alias.new(odb)
  view=View.new(cobj.stat,odb).add(opt)
rescue SelectID
  abort "Usage: clsshell (-alsp) [cls] [id] [iocmd]\n#{$!}"
end
cobj.session{|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||view.upd
}
