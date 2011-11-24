#!/usr/bin/ruby
require "libmsg"
require "thread"

# Command stream(Send)
# send() takes frame cmds in block
# -> Inbuf[priority]
# -> Accept or Reject
# -> flush -> Queue
#
# Command stream(Recieve)
# recv()
# Queue -> Outbuf until Queue is empty
# -> provide single frmcmd as it is called
# (stack if Queue is empty)

class Buffer
  attr_reader :issue
  def initialize
    @v=Msg::Ver.new("buffer",2)
    @q=Queue.new
    @tid=nil
    clear
  end

  def send(n=1)
    return self if  n > 1 && !@q.empty?
    clear if n == 0
    inp=yield
    unless inp.empty?
      @issue=true
      @q.push([n,inp])
    end
    self
  end

  # For cmdset thread
  def recv
    @issue=false
    until out=pick
      @v.msg{"SUB:Waiting"}
      p,inp=@q.shift
      @v.msg{"SUB:Recieve [#{inp}] with priority[#{p}]"}
      (@outbuf[p]||=[]).concat(inp)
    end
    out
  end

  def thread
    @tid=Thread.new{
      Thread.pass
      loop{
        begin
          yield recv
        rescue UserError
          warn $!
          Msg.alert(" in Buffer Thread")
          clear
        end
      }
    }
    self
  end

  def alive?
    @tid && @tid.alive?
  end

  # Internal command
  private
  def pick
    cmd=nil
    @outbuf.size.times{|i|
      if cmd
        @outbuf[i].delete(cmd)
      else
        cmd=@outbuf[i].shift
      end
    }
    cmd
  end

  def clear
    @issue=false
    @outbuf=[[],[],[]]
    @q.clear
    @tid && @tid.run
  end
end
