#!/usr/bin/ruby
require "libmsg"
require "thread"

# SubModule for AppSv
# *Command stream(Send)
#  send() takes frame cmds in block
#  -> Inbuf[priority]
#  -> Accept or Reject
#  -> flush -> Queue
#
# *Command stream(Recieve)
#  recv()
#  Queue -> Outbuf until Queue is empty
#  -> provide single frmcmd as it is called
#  (stack if Queue is empty)

class Buffer
  attr_reader :issue
  def initialize
    @v=Msg::Ver.new(self,2)
    @q=Queue.new
    @tid=nil
    clear
  end

  # Send bunch of frmcmd array (ary of ary)
  def send(n=1)
    return self if  n > 1 && !@q.empty?
    clear if n == 0
    inp=yield
    #inp is frmcmd array (ary of ary)
    unless inp.empty?
      @q.push([n,inp])
    end
    self
  end

  # For cmdset thread
  def recv
    until out=pick
      @v.msg{"SUB:Waiting"}
      @issue=false
      #inp is frmcmd array (ary of ary)
      p,inp=@q.shift
      @issue=true
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

  private
  # Remove duplicated commands and pop one
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
