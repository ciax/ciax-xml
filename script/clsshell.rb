#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libiocmd"
require "libiostat"
require "libclsobj"
require "libfrmobj"
require "libalias"
require "libview"
require "libshell"

cls=ARGV.shift
opt='alsp'
if (/^-/ === cls)
  opt=cls.delete('-')
  cls=ARGV.shift
end
id=ARGV.shift
iocmd=ARGV.shift
al=Alias.new(id)
begin
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  field=IoStat.new(id,'field')
  io=IoCmd.new(iocmd,id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
  cobj=ClsObj.new(cdb,id,field){|stm|
    fobj.request(stm)
  }
  odb=ObjDb.new(id,cls)
  view=View.new(cobj.stat).add(odb,opt)
rescue SelectID
  abort "Usage: clsshell (-alsp) [cls] [id] [iocmd]\n#{$!}"
end
Shell.new(cobj.prompt){|line|
  cobj.upd
  case line
  when nil
    cobj.interrupt
  when ''
    view.upd
  else
    cobj.dispatch(al.alias(line.split(" ")))
  end
}
