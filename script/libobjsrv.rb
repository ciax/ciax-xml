#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv < Obj
  def initialize(obj)
    super
    @ddb=DevCom.new(self['device'],self['client'],obj)
    @auto=nil
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

  def dispatch(line)
    objcom(line) {|c,p|
      @q.push([c,p])
      @ddb.field
    }
  rescue
    list=$!.to_s+"\n"
    cmd,par=line.split(' ')
    case cmd
    when 'auto'
      auto_update(par)
    else
      list+"auto\t:Auto command (cmd)"
    end
  else
    "Accept\n"
  end


  def session(line)
    begin
      objcom(line) {|c,p|
        @q.push([c,p])
        @ddb.field
      }
    rescue
      $!.to_s+"\n"
    else
      "Accept\n"
    end
  end

  def auto_update(cmd,int=10)
    case cmd
    when 'stop'
      @auto.kill
    else
      @auto=Thread.new {
        loop{
          session(cmd)
          sleep int
        }
      }
    end
  end

end
