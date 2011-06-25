#!/usr/bin/ruby
require "json"
require "libclsobj"
require "libfrmobj"
require "libclsdb"
require "libfrmdb"
require "libserver"
require "libfilter"
require "libalias"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
inp=Alias.new(id)
begin
  cdb=ClsDb.new(cls)
  fdb=FrmDb.new(cdb['frame'])
  fobj=FrmObj.new(fdb,id,iocmd)
  cobj=ClsObj.new(cdb,id,fobj.field){|stm|
    fobj.request(stm)
  }
rescue SelectID
  abort "Usage: clsserver [cls] [id] [port] [iocmd] (outcmd)\n#{$!}"
end
Server.new(port){|line|
  case line
  when '',/stat/
  when /stop/
    cobj.interrupt
  else
    line.split(';').each{|cmd|
      cmda=cmd.split(' ')
      cobj.dispatch(inp.alias(cmda))
    }
  end
  out.filter(JSON.dump(cobj.stat))
}
