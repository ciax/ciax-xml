#!/usr/bin/ruby
require "optparse"
require "json"
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

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
obj,iocmd=ARGV

begin
  odb=ObjDb.new(obj)
  odb >> ClsDb.new(odb['class'])
  fdb=FrmDb.new(odb['frame'])
rescue SelectID
  abort "Usage: clsint (-s) [obj] (iocmd)\n#{$!}"
end

stat=IoStat.new(obj,'json/status')
field=IoStat.new(obj,'field')

io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
fobj=FrmObj.new(fdb,field,io)

cobj=ClsObj.new(odb,stat,field){|cmd|
  fobj.request(cmd)
}

al=Alias.new(odb)
view=View.new(stat).opt('als',odb[:status])
prt=Print.new(view)

port=opt[:s] ? odb["port"] : nil

Interact.new(cobj.prompt,port){|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||\
  (port ? stat.to_j : prt.upd)
}
