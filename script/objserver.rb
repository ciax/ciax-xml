#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"

warn "Usage: objserver [obj] [port] [iocmd]" if ARGV.size < 2

obj=ARGV.shift
@odb=Obj.new(obj)
port=ARGV.shift
srv=IoCmd.new("socat - udp-l:#{port},reuseaddr,fork",1)
@ddb=Dev.new(@odb.property['device'],ARGV.shift)

line='upd'

def session(line)
  begin
    @odb.objcom(line) do |l|
      @ddb.devcom(l)
    end
  rescue
    $!.to_s+"\n"
  else
    "Accept\n"
  end
end


loop do 
  if line=srv.rcv
    srv.snd(session(line)+"#{obj}>")
  else
    session('upd')
  end
end
