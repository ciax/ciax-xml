#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"

warn "Usage: objserver [obj] [port] [iocmd]" if ARGV.size < 2

obj=ARGV.shift
@odb=Obj.new(obj)
port=ARGV.shift
srv=IoCmd.new("socat - udp-l:#{port},reuseaddr,fork")
@ddb=Dev.new(@odb.property['device'],ARGV.shift)

line='upd'

def session(line)
  cmd,par=line.split(' ')
  begin
    @odb.objcom(cmd,par) do |c,p|
      @ddb.devcom(c,p)
    end
  rescue
    $!
  end
  nil
end


loop do 
  if line=srv.rcv
    resp=session(line) || "#{obj}>"
    srv.snd(resp)
  else
    warn session('upd')
  end
end
