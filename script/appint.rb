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

view=View.new(obj).load
view['app_type']=app
view.opt('als',odb[:status]).upd
io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
fobj=FrmObj.new(fdb,Field.new(obj),io)

cobj=AppObj.new(odb,view){|cmd|
  fobj.request(cmd).field
}

al=Alias.new(odb)
prt=Print.new(view)

port=opt[:s] ? odb["port"] : nil

Interact.new(cobj.prompt,port){|line|
  cobj.dispatch(line){|cmd| al.alias(cmd)}||\
  (port ? view.to_j : prt.upd)
}
