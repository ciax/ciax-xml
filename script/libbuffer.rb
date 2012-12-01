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
  attr_reader :flush_proc
  # svst: Server Status
  def initialize(svst=[])
    Buffer.init_ver(self)
    @svst=Msg.type?(svst,Hash)
    #element of @q is bunch of frmcmds corresponding an appcmd
    @q=Queue.new
    @tid=nil
    @flush_proc=Update.new.add{Buffer.msg{"Flushing"}}
    @send_proc=proc{}
    clear
  end

  def send_proc
    @send_proc=proc{yield}
    self
  end

  # Send bunch of frmcmd array (ary of ary)
  def send(n=1)
    clear if n == 0
    inp=@send_proc.call
    #inp is frmcmd array (ary of ary)
    unless inp.empty?
      @svst['isu']=true
      @q.push([n,inp])
    end
    self
  end

  def recv_proc
    @tid=Thread.new{
      tc=Thread.current
      tc[:name]="Buffer"
      tc[:color]=10
      Thread.pass
      loop{
        begin
          sort(*@q.shift)
          while out=pick
            yield out
          end
          flush
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
  def flush
    Buffer.msg{"SUB:Waiting"}
    # @q can not be empty depending on @flush_proc
    @svst['isu']=false if @q.empty?
    @flush_proc.upd
  end

  #inp is frmcmd array (ary of ary)
  def sort(p,inp)
    Buffer.msg{"SUB:Recieve [#{inp}] with priority[#{p}]"}
    (@outbuf[p]||=[]).concat(inp)
    Buffer.msg{i=-1;
      @outbuf.map{|o|
        "SUB:Outbuf(#{i+=1}) is [#{o}]\n"
      }
    }
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
