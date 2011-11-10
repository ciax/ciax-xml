#!/usr/bin/ruby
require "libmsg"
require "thread"

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
      @v.msg{"MAIN:Issued [#{cmd}] with priority [#{n}]"}
    }
    flush(n) unless @wait
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
        @outbuf.each{|buf|
          next if ! buf || buf.empty?
          cmd=buf.shift
          @v.msg{"SUB:Exec [#{cmd}]"}
          return cmd
        }
        @v.msg{"SUB:Waiting"}
      end
      p,cmd=@q.shift
      @v.msg{"SUB:Recieve [#{cmd}] with priority[#{p}]"}
      @outbuf[p] ||= []
      @outbuf[p].push(cmd)
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
  end
end
