#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"

warn "Usage: objserver [obj] [port] [iocmd]" if ARGV.size < 2

obj=ARGV.shift
odb=Obj.new(obj)
port=ARGV.shift
srv=IoCmd.new("socat - udp-l:#{port},reuseaddr,fork")
ddb=Dev.new(odb.property['device'],ARGV.shift)

line='upd'
loop do 
  if line=srv.rcv
    cmd,par=line.split(' ')
  else
    cmd='upd'
  end
  begin
    odb.objcom(cmd,par) do |c,p|
      ddb.devcom(c,p)
    end
  rescue
    srv.snd=$!
  else
    srv.snd "#{obj}>"if line
  end
end
