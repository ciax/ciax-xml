#!/usr/bin/ruby
require "optparse"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libfrmobj"
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
  odb >> ClsDb.new(odb['app_type'])
  fdb=FrmDb.new(odb['frame'])
  field=IoStat.new(obj,'field')
  io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue SelectID
  abort "Usage: frmint (-s) [obj] (iocmd)\n#{$!}"
end
port=opt[:s] ? odb["port"] : nil
Interact.new([odb['frame'],'>'],port){|line|
  (line && fobj.request(line.split(' ')))||\
  (port ? field.to_j : field)
}
