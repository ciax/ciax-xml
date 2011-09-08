#!/usr/bin/ruby
require "optparse"
require "libobjdb"
require "libfrmdb"
require "libfrmobj"
require "libiocmd"
require "libfield"
require "libinteract"

opt={}
OptionParser.new{|op|
  op.on('-s'){|v| opt[:s]=v}
  op.parse!(ARGV)
}
obj,iocmd=ARGV
begin
  odb=ObjDb.new(obj).cover_app
  fdb=FrmDb.new(odb['frm_type'])
  field=Field.new(obj).load
  field.update(odb[:field]) if odb.key?(:field)
  io=IoCmd.new(iocmd||odb['client'],obj,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue SelectID
  abort "Usage: frmint (-s) [obj] (iocmd)\n#{$!}"
end
port=opt[:s] ? odb["port"] : nil
Interact.new([odb['frame'],'>'],port){|line|
  (line && fobj.request(line.split(' ')).to_s)||\
  (port ? field.to_j : field)
}
