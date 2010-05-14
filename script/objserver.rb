#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
@odb=Obj.new(obj)
dev=@odb.property['device']
client=@odb.property['client']
server=@odb.property['server']
srv=IoCmd.new(server,1)
@ddb=Dev.new(dev,client)
warn server

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
