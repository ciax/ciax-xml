#!/usr/bin/ruby
require "libcls"
require "libxmldoc"
require "libserver"

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 1

$DEBUG=true
cls=ARGV.shift
id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,id,iocmd)
Server.new(port){|line|
  case line
  when ''
  when /stop/
    cdb.interrupt
  else
    line.split(';').each{|stm|
      cdb.dispatch(stm.split(' ')){|s|s}
    }
  end
  cdb.stat.inspect+"\n"+cdb.prompt
}
