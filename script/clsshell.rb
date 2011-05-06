#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libclsdb"
require "libxmldoc"
require "libalias"
require "libshell"

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
al=Alias.new(id)
begin
  cdb=ClsDb.new(cls)
  fdoc=XmlDoc.new('fdb',cdb['frame'])
  fctl=Frm.new(fdoc,id,iocmd)
  cctl=Cls.new(cdb,id){|stm|
    fctl.request(stm)
    fctl.stat
  }
rescue SelectID
  abort "Usage: clsshell [cls] [id] [iocmd] (outcmd)\n#{$!}"
end
Shell.new(cctl,filter){|stm|
  stm=al.alias(stm)
  cctl.dispatch(stm)
}
