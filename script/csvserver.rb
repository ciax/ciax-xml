#!/usr/bin/ruby
require "libcls"
require "libxmldoc"
require "socket"

def keylist(dev)
  list=[]
  open("/home/ciax/config/sdb_#{dev}.txt"){|f|
    while line=f.gets
      next unless /.+/ === line
      list << line.split(',').first
    end
  }
  list
end

def mkres(stat)
  res="%#{$id}_#{stat['exe']}#{stat['isu']}_"
  $klist.each{|key|
    res << stat[key]
  }
  res
end

warn "Usage: clsserver [cls] [id] [port] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
$id=ARGV.shift
port=ARGV.shift
iocmd=ARGV.shift
$klist=keylist($id)
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,$id,iocmd)
UDPSocket.open{ |udp|
  udp.bind("0.0.0.0",port)
  loop {
    msg=''
    begin
      select([udp])
      line,addr=udp.recvfrom(1024)
      case line.chomp!
      when 'stat'
      when /stop/
        cdb.interrupt
      else
        line.split(';').each{|stm|
          cdb.dispatch(stm.split(' ')){|s|s}
        }
      end
    rescue RuntimeError
      msg=$!.to_s
    end
    udp.send(mkres(cdb.stat),0,addr[2],addr[1])
  }
}
