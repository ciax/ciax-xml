#!/usr/bin/ruby
require "libmsg"
require "thread"
require "libupdate"

# SubModule for App::Sv
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
  extend Msg::Ver
  attr_reader :issue,:post_flush
  def initialize
    Buffer.init_ver(self)
    #element of @q is bunch of frmcmds corresponding an appcmd
    @q=Queue.new
    @tid=nil
    @post_flush=Update.new
    @proc_send=proc{}
    clear
  end

  def proc_send
    @proc_send=proc{yield}
    self
  end

  # Send bunch of frmcmd array (ary of ary)
  def send(n=1)
    clear if n == 0
    inp=@proc_send.call
    #inp is frmcmd array (ary of ary)
    unless inp.empty?
      @q.push([n,inp])
    end
    self
  end

  def proc_recv
    @tid=Thread.new{
      Thread.pass
      loop{
        begin
          yield recv
        rescue UserError
          warn $!.to_s.chomp
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
  # For cmdset thread
  def recv
    until out=pick
      flush
      #inp is frmcmd array (ary of ary)
      p,inp=@q.shift
      @issue=true
      Buffer.msg{"SUB:Recieve [#{inp}] with priority[#{p}]"}
      (@outbuf[p]||=[]).concat(inp)
      Buffer.msg{i=-1;
        @outbuf.map{|o|
          "SUB:Outbuf(#{i+=1}) is [#{o}]\n"
        }
      }
    end
    out
  end

  def flush
    Buffer.msg{"SUB:Waiting"}
    @issue=false
    @post_flush.upd
  end

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
