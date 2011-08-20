#!/usr/bin/ruby
require "json"
require "libcache"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libfrmobj"
require "libclsdb"
require "libclsobj"
require "libalias"
require "libview"
require "libprint"
require "libiocmd"
require "libiostat"
require "libinteract"

opt,arg = ARGV.partition{|s| /^-/ === s}
opt= opt.empty? ? 'als' : opt.join('')
cls,obj,iocmd,port=arg

begin
  cdb=ClsDb.new(cls)
  odb=ObjDb.new(obj).cover(cdb)
  fdb=FrmDb.new(odb['frame'])
rescue SelectID
  abort "Usage: clsint (-als) [cls] [obj] [iocmd] (port)\n#{$!}"
end

stat=IoStat.new(obj,'json/status')
field=IoStat.new(obj,'field')

io=IoCmd.new(iocmd,obj,fdb['wait'],1)
fobj=FrmObj.new(fdb,field,io)

cobj=ClsObj.new(odb,stat,field){|cmd|
  fobj.request(cmd)
}

al=Alias.new(odb)
view=View.new(stat).opt(opt,odb[:status])
prt=Print.new(view)

Interact.new(port||cobj.prompt){|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||\
  (port ? stat.to_j : prt.upd)
}
