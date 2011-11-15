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
    @proc=Queue.new
    @st=delay
    clear
  end

  def send(n=1)
    return self if  n > 1 && !@q.empty?
    clear if n == 0
    yield.each{|cmd|
      @inbuf[n].push(cmd)
      @v.msg{"MAIN:Issued frmcmd [#{cmd}] with priority [#{n}]"}
    }
    flush(n)
    self
  end

  def wait(timeout=10) # Need Block of boolean
    @wait=timeout.to_i
    prc=defined?(yield) ? Proc.new : Proc.new{}
    @proc.push(prc)
    self
  end

  def wait?
    @wait
  end

  # For cmdset thread
  def recv
    @issue=false
    loop{
      if @q.empty?
        cmd=nil
        @outbuf.size.times{|i|
          if cmd
            @outbuf[i].delete(cmd)
          else
            cmd=@outbuf[i].shift
          end
        }
        if cmd
          @v.msg{"SUB:Exec [#{cmd}]"}
          if cmd[0] == 'sleep'
            sleep cmd[1].to_i
            redo
          else
            return cmd
          end
        end
        @v.msg{"SUB:Waiting"}
      end
      p,cmd=@q.shift
      @v.msg{"SUB:Recieve [#{cmd}] with priority[#{p}]"}
      (@outbuf[p]||=[]).push(cmd)
    }
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
  def delay
    Thread.new{
      Thread.pass
      loop{
        cond=@proc.shift
        dl=Time.now+@wait
        sleep 1 until cond.call || dl < Time.now
        @wait=false
      }
    }
  end

  def flush(pri)
    unless @inbuf[pri].empty?
      @issue=true
      @wait=false
      @inbuf[pri].each{|cmd| @q.push([pri,cmd]) }
      @v.msg{"MAIN:Flushed #{@inbuf[pri]}"}
      @inbuf[pri]=[]
    end
    self
  end

  def clear
    @issue=@wait=false
    @inbuf=[[],[],[]]
    @outbuf=[[],[],[]]
    @q.clear
    @tid && @tid.run
  end
end
