#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv
  def initialize(obj)
    @odb=Obj.new(obj)
    @ddb=DevCom.new(@odb['device'],@odb['client'],obj)
    @auto=nil
    @int=10
    @q=Queue.new
    Thread.new {
      loop {
        c,p=@q.shift
        begin
          @ddb.setcmd(c,p)
          @ddb.devcom
        rescue
          warn $!
        end
      }
    }
  end

  def server
    @odb['server']
  end

  def dispatch(line)
    cmd=line.split(' ')
    case cmd.shift
    when 'auto'
      auto_update(*cmd)
    when 'stat'
      yield @odb.stat
    else
      session(line)
    end
  rescue
    $!.to_s+"\nauto\t:Auto command [cmd] (int)\n"
  end

  private
  def session(line)
    @odb.objcom(line) {|c,p|
      @q.push([c,p])
      @ddb.field
    }
    "Accept\n"
  end

  def auto_update(cmd,int=nil)
    @int=int.to_i if int
    case cmd
    when 'stop'
      @auto.kill
      "Auto Update Stop\n"
    else
      @auto=Thread.new {
        begin
          loop{
            session(cmd) if @q.empty?
            sleep @int
          }
        rescue
          warn $!.to_s
        end
      }
      "Auto Update [#{cmd}] every #{@int}s\n"
    end
  rescue
    $!.to_s
  end

end
