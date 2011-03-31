#!/usr/bin/ruby
require "libcls"
require "libfrm"
require "libxmldoc"
require "libserver"

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 4

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
begin
  cdoc=XmlDoc.new('cdb',cls)
  fdoc=XmlDoc.new('fdb',cdoc['frame'])
  fdb=Frm.new(fdoc,id,iocmd)
  cdb=Cls.new(cdoc,id,fdb)
rescue SelectID
  abort $!.to_s
end
Server.new(port){|line|
  case line
  when ''
  when /stop/
    cdb.interrupt
  else
    line.split(';').each{|cmd|
      cdb.dispatch(cmd.split(' '))
    }
  end
  cdb.stat.inspect+"\n"+cdb.prompt
}
