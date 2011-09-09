#!/usr/bin/ruby
require "optparse"
require "json"
require "libentdb"
require "libview"
require "libfield"
require "libiocmd"
require "libfrmdb"
require "libfrmobj"
require "libappdb"
require "libappobj"
require "libprint"
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
rescue SelectID
  abort "Usage: appint (-s) [id] (iocmd)\n#{$!}"
end

stat=View.new(id,edb[:status]).load
stat['app_type']=edb['app_type']
field=Field.new(id).load
field.update(edb[:field]) if edb.key?(:field)

io=IoCmd.new(iocmd||edb['client'],id,fdb['wait'],1)
fobj=FrmObj.new(fdb,field,io)

aobj=AppObj.new(edb,stat){|cmd|
  fobj.request(cmd).field
}

prt=Print.new(edb[:status])

port=opt[:s] ? edb["port"] : nil

Interact.new(aobj.prompt,port){|line|
  aobj.dispatch(line){port ? nil : prt.upd(stat)}
}
