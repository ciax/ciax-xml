#!/usr/bin/ruby
require "libverbose"
require "thread"

class Buffer
  def initialize
    @inbuf=[[],[],[]]
    @outbuf=[[],[],[]]
    @q=Queue.new
    @v=Verbose.new("BUF",5)
    @issue=@wait=false
    @proc=Queue.new
    @st=delay
  end

  def send
    cmdset=yield
    raise "Cmdset should be Array" unless Array === cmdset
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

  def interrupt(cmd=[])
    @v.msg{"MAIN:Stopped"}
    @issue=@wait=false
    @q.clear
    @v.msg{"MAIN:Issued #{cmd}"}
    @inbuf[0]=cmd
    flush(0)
  end

  def wait_for(timeout=10) # Need Block of boolean
    @wait=timeout.to_i
    @proc.push(proc)
    self
  end

  def issue?
    @issue
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

  # Internal command
  private
  def delay
    Thread.new{
      Thread.pass
      loop{
        proc=@proc.shift
        dl=Time.now+@wait
        while @wait
          sleep 1
          if proc.call || dl < Time.now
            flush
            break
          end
        end
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
