#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libclsdb"
require "libfrmdb"
require "libserver"
require "libfilter"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
begin
  cdoc=ClsDb.new(cls)
  fdoc=FrmDb.new(cdoc['frame'])
  fobj=Frm.new(fdoc,id,iocmd)
  cobj=Cls.new(cdoc,id){|stm|
    fobj.request(stm)
    fobj.stat
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
      cobj.dispatch(cmd.split(' '))
    }
  end
  out.filter(JSON.dump(cobj.stat))
}
