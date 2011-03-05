#!/usr/bin/ruby
require "libcls"
require "libxmldoc"
require "socket"

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 1

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
UDPSocket.open{ |udp|
  udp.bind("0.0.0.0",port)
  loop {
    msg=''
    begin
      select([udp])
      line,addr=udp.recvfrom(1024)
      case line.chomp!
      when ''
        msg=cdb.stat.inspect+"\n"
      when /stop/
        msg=cdb.interrupt+"\n"
      else
        line.split(';').each{|stm|
          cdb.dispatch(stm.split(' ')){|s|s}
        }
      end
    rescue RuntimeError
      msg=$!.to_s
    end
    udp.send(msg+cdb.prompt,0,addr[2],addr[1])
  }
}
