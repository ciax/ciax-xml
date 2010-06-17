#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"
require "thread"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
@odb=Obj.new(obj)
server=@odb.odb['server']
srv=IoCmd.new(server,"server_#{obj}",0,10)
warn server
@q=Queue.new

Thread.new {
  dev=@odb.odb['device']
  client=@odb.odb['client']
  @ddb=DevCom.new(dev,client,obj)
  loop {
    begin
      @odb.objcom(@q.pop) {|c,p|
        begin
          @ddb.setpar(p)
          @ddb.setcmd(c)
          @stat=@ddb.devcom
        rescue
        end
      }
    rescue
      $!.to_s+"\n"
    else
      "Accept\n"
    end
  }
}

loop{
  if line=srv.rcv
    line.chomp!
    if line == ''
      srv.snd(@stat.to_s+"\n")
    else
      @q.push(line)
    end
    srv.snd("#{obj}>")
  else
    @q.push('upd')
  end
}
