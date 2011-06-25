#!/usr/bin/ruby
require "json"
require "libclsobj"
require "libfrmobj"
require "libclsdb"
require "libfrmdb"
require "libshell"
require "libascpck"
require "libalias"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
inp=Alias.new(id)
begin
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  fobj=FrmObj.new(fdb,id,iocmd)
  cobj=ClsObj.new(cdb,id,fobj.field){|stm|
    fobj.request(stm)
  }
  ap=AscPck.new(id,cobj.stat)
rescue SelectID
  abort "Usage: apserver [cls] [id] [port] [iocmd]\n#{$!}"
end
if port == '0'
  require "libshell"
  int=Shell
  port=['>']
else
  require "libserver"
  int=Server
end

int.new(port){|line|
  cobj.upd
  case line
  when ''
    ap.upd
  when /stop/
    cobj.interrupt
  else
    ap.isu
    cobj.dispatch(inp.alias(line.split(' ')))
  end
}
