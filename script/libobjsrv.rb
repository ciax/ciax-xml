#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv < Obj
  def initialize(obj)
    super
    @ddb=DevCom.new(self['device'],self['client'],obj)
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

  def auto_update
    Thread.new {
      loop{
        session('upd')
        sleep 10
      }
    }
  end

end
