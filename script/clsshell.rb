#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libclsdb"
require "libfrmdb"
require "libalias"
require "libshell"

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
al=Alias.new(id)
begin
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  fobj=Frm.new(fdb,id,iocmd)
  cobj=Cls.new(cdb,id){|stm|
    fobj.request(stm)
    fobj.stat
  }
rescue SelectID
  abort "Usage: clsshell [cls] [id] [iocmd] (outcmd)\n#{$!}"
end
Shell.new(cobj,filter){|stm|
  stm=al.alias(stm)
  cobj.dispatch(stm)
}
