#!/usr/bin/ruby
require "optparse"
require "json"
require "libobjdb"
require "libappdb"
require "libview"
require "libfield"
require "libiocmd"
require "libfrmdb"
require "libfrmobj"
require "libappdb"
require "libappobj"
require "libalias"
require "libprint"
require "libinteract"

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
obj,iocmd=ARGV

begin
  odb=ObjDb.new(obj)
  app=odb['app_type']
  odb >> AppDb.new(app)
  fdb=FrmDb.new(odb['frm_type'])
rescue SelectID
  abort "Usage: appint (-s) [obj] (iocmd)\n#{$!}"
end

stat=View.new(obj,odb[:status]).load.upd
stat['app_type']=app
field=Field.new(obj).load
field.update(odb[:field]) if odb.key?(:field)

io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
fobj=FrmObj.new(fdb,field,io)

cobj=AppObj.new(odb,stat){|cmd|
  fobj.request(cmd).field
}

al=Alias.new(odb)
prt=Print.new(odb[:status])

port=opt[:s] ? odb["port"] : nil

Interact.new(cobj.prompt,port){|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||\
  (port ? stat.to_j : prt.upd(stat))
}
