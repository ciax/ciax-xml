#!/usr/bin/ruby
require "optparse"
require "json"
require "libobjdb"
require "libappdb"
require "libfrmdb"
require "libfrmobj"
require "libappdb"
require "libappobj"
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
  odb >> AppDb.new(odb['app_type'])
  fdb=FrmDb.new(odb['frm_type'])
rescue SelectID
  abort "Usage: appint (-s) [obj] (iocmd)\n#{$!}"
end

stat=IoStat.new(obj,'json/status')

io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
fobj=FrmObj.new(fdb,IoStat.new(obj,'field'),io)

cobj=AppObj.new(odb,stat){|cmd|
  fobj.request(cmd).field
}

al=Alias.new(odb)
view=View.new(stat).opt('als',odb[:status])
prt=Print.new(view)

port=opt[:s] ? odb["port"] : nil

Interact.new(cobj.prompt,port){|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||\
  (port ? stat.to_j : prt.upd)
}
