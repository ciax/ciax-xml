#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libalias"
require "libprint"
require "libviewopt"
require "libclssrv"
require "libshell"

opt,arg = ARGV.partition{|s| /^-/ === s}
opt= opt.empty? ? 'alsp' : opt.join('')
cls,obj,iocmd=arg

begin
  cobj=ClsSrv.new(obj,cls,iocmd)
  odb=ObjDb.new(obj,cls)
  al=Alias.new(odb)
  view=ViewOpt.new(odb,cobj.stat).opt(opt)
  prt=Print.new(view)
rescue SelectID
  abort "Usage: clsshell (-alsp) [cls] [obj] [iocmd]\n#{$!}"
end
cobj.session{|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||prt.upd
}
