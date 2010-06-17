#!/usr/bin/ruby
require "libobj"
require "libdev"
require "libiocmd"
require "thread"

warn "Usage: objserver [obj]" if ARGV.size < 1

obj=ARGV.shift
@odb=Obj.new(obj)
server=@odb.odb['server']
srv=IoCmd.new(server,"server_#{obj}",0,nil)
dev=@odb.odb['device']
client=@odb.odb['client']
@ddb=DevCom.new(dev,client,obj)
warn server
@q=Queue.new

Thread.new {
  loop {
    c,p=@q.pop
    begin
      @ddb.setpar(p)
      @ddb.setcmd(c)
      @ddb.devcom
    rescue
      warn $!
    end
  }
}

Thread.new {
  loop{
    session('upd')
    sleep 10
  }
}

def session(line)
  begin
    @odb.objcom(line) {|c,p|
      @q.push([c,p])
      @ddb.field
    }
  rescue
    $!.to_s+"\n"
  else
    "Accept\n"
  end
end

while line=srv.rcv
  line.chomp!
  case line
  when ''
    srv.snd(@odb.stat.inspect+"\n")
  else
    srv.snd(session(line))
  end
  srv.snd("#{obj}>")
end
