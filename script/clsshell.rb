#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libxmldoc"
require "libalias"
require "libshell"

usage="Usage: clsshell [cls] [id] [iocmd] (outcmd)"
cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
al=Alias.new(id)
begin
  cdoc=XmlDoc.new('cdb',cls,usage)
  fdoc=XmlDoc.new('fdb',cdoc['frame'])
  fdb=Frm.new(fdoc,id,iocmd)
  cdb=Cls.new(cdoc,id){|stm|
    fdb.request(stm)
    fdb.stat
  }
rescue SelectID
  abort $!.to_s
end
Shell.new(cdb,filter){|stm|
  stm=al.alias(stm)
  cdb.dispatch(stm)
}
