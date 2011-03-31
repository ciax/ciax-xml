#!/usr/bin/ruby
require "libcls"
require "libfrm"
require "libxmldoc"
require "libcxcsv"
require "libserver"

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 1
cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
begin
  cdoc=XmlDoc.new('cdb',cls)
  fdoc=XmlDoc.new('fdb',cdoc['frame'])
rescue SelectID
  abort $!.to_s
end
fdb=Frm.new(fdoc,id,iocmd)
cdb=Cls.new(cdoc,id,fdb)
cx=CxCsv.new(id)
Server.new(port){|line|
  case line
  when 'stat',''
  when /stop/
    cdb.interrupt
  else
    line.split(';').each{|stm|
      cdb.dispatch(stm.split(' '))
    }
  end
  cx.mkres(cdb.stat)
}
