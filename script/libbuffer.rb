#!/usr/bin/ruby
require "libmsg"
require "thread"

class Buffer
  attr_reader :issue,:wait
  def initialize
    @v=Msg::Ver.new("buffer",2)
    @q=Queue.new
    @proc=Queue.new
    @st=delay
    clear
  end

  def clear
    @issue=@wait=false
    @inbuf=[[],[],[]]
    @outbuf=[[],[],[]]
    @q.clear
  end

  def send(cmdset)
    Msg.type?(cmdset,Array)
    cmdset.each{|cmd|
      @inbuf[1].push(cmd)
      @v.msg{"MAIN:Issued [#{cmd}] with priority [normal]"}
    }
    flush(1) unless @wait
    self
  end

  def auto
    if @q.empty?
      yield.each{|cmd|
        @inbuf[2].push(cmd)
      }
      flush(2)
    end
    self
  end

  def interrupt
    @v.msg{"MAIN:Stopped"}
    clear
    yield.each{|cmd|
      @inbuf[0].push(cmd)
      @v.msg{"MAIN:Issued #{cmd}"}
    }
    flush(0)
  end

  def wait_for(timeout=10) # Need Block of boolean
    @wait=timeout.to_i
    @proc.push(proc)
    self
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
end
