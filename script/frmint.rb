#!/usr/bin/ruby
require "optparse"
require "libentdb"
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
id,iocmd=ARGV
begin
  edb=EntDb.new(id).cover_app
  fdb=FrmDb.new(edb['frm_type'])
  field=Field.new(id).load
  field.update(edb[:field]) if edb.key?(:field)
  io=IoCmd.new(iocmd||edb['client'],id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue SelectID
  abort "Usage: frmint (-s) [id] (iocmd)\n#{$!}"
end
port=opt[:s] ? edb["port"] : nil
Interact.new([edb['frame'],'>'],port){|line|
  fobj.request(line.split(' ')){port ? field.to_j : field} if line
}
