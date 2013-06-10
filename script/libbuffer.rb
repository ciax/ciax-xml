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
  include Msg::Ver
  attr_reader :flush_proc
  # svst: Server Status
  def initialize(svst=[])
    @svst=Msg.type?(svst,Hash)
    #element of @q is bunch of frmcmds corresponding an appcmd
    @q=Queue.new
    @tid=nil
    @flush_proc=UpdProc.new.add{verbose("Buffer","Flushing")}
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
        rescue
          warn $!.to_s.chomp
          fatal("Buffer"," in Buffer Thread")
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
    verbose("Buffer","SUB:Waiting")
    # @q can not be empty depending on @flush_proc
    @flush_proc.upd
    @svst['isu']=false if @q.empty?
  end

  #inp is frmcmd array (ary of ary)
  def sort(p,inp)
    verbose("Buffer","SUB:Recieve [#{inp}] with priority[#{p}]")
    (@outbuf[p]||=[]).concat(inp)
    i=-1
    @outbuf.map{|o|
      verbose("Buffer","SUB:Outbuf(#{i+=1}) is [#{o}]\n")
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
