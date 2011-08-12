#!/usr/bin/ruby
require "json"
require "libiocmd"
require "libascpck"

id,iocmd,port=ARGV

begin
  @stat={}
  @io=IoCmd.new(iocmd)
  @ap=AscPck.new(id,@stat)
rescue SelectID
  abort "Usage: aprelay [id] [iocmd] (port)\n#{$!}"
end

def session(line)
  if line.empty?
    line='stat'
  else
    @ap.issue
  end
  @io.snd(line)
  time,str=@io.rcv
  begin
  @stat.update(JSON.load(str))
  rescue
  end
  @ap.upd
end

if port.to_i > 0
  require "libserver"
  Server.new(port){|line|
    session(line)
  }
else
  require "libshell"
  Shell.new(['>']){|line|
    session(line)
  }
end
