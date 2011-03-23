#!/usr/bin/ruby
require "libcls"
require "libxmldoc"
require "libcxcsv"
require "libserver"

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 1
cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
cx=CxCsv.new(id)
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,id,iocmd)
Server.new(port){|line|
  case line
  when 'stat',''
  when /stop/
    cdb.interrupt
  else
    line.split(';').each{|stm|
      cdb.dispatch(stm.split(' ')){|s|s}
    }
  end
  cx.mkres(cdb.stat)
}
