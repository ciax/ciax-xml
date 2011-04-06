#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libxmldoc"
require "libserver"
require "libfilter"

usage="Usage: clsserver [cls] [id] [port] [iocmd] (outcmd)\n"

cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
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
Server.new(port){|line|
  case line
  when '',/stat/
  when /stop/
    cdb.interrupt
  else
    line.split(';').each{|cmd|
      cdb.dispatch(cmd.split(' '))
    }
  end
  out.filter(JSON.dump(cdb.stat))
}
