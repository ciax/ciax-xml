#!/usr/bin/ruby
require "libverbose"
require "thread"

class CmdBuf
  def initialize
    @inbuf=Array.new
    @outbuf=Array.new
    @q=Queue.new
    @v=Verbose.new("BUF")
    @issue=@wait=nil
    @proc=Queue.new
    @st=delay
  end

  def send
    stms=yield
    raise "Should be Array of statements" unless Array === stms
    stms.each{|stm|
      @inbuf.push([1,stm])
      @v.msg{"MAIN:Issued [#{stm}] with priority [normal]"}
    }
    flush unless @wait
    self
  end

  def auto
    if @q.empty?
      yield.each{|stm|
        @inbuf.push([2,stm])
      }
      flush
    else
      @v.msg{"MAIN:Rejected [#{stms}] with priority [auto]"}
    end
  end

  def interrupt(cmds=[])
    @v.msg{"MAIN:Stopped"}
    @issue=@wait=nil
    @q.clear
    @v.msg{"MAIN:Issued #{cmds}"}
    @inbuf.replace(cmds.map!{|c| [0,c]})
    flush
  end

  def wait_for(timeout=10) # Need Block of boolean
    @wait=timeout.to_i
    @proc.push(proc)
  end

  def issue?
    @issue
  end

  def wait?
    @wait
  end

  # For session thread
  def recv
    @issue=nil
    loop{
      if @q.empty?
        @outbuf.each{|c|
          next if ! c || c.empty?
          stm=c.shift
          @v.msg{"SUB:Exec [#{stm}]"}
          return stm
        }
        @v.msg{"SUB:Waiting"}
      end
      p,stm=@q.shift
      @v.msg{"SUB:Recieve [#{stm}] with priority[#{p}]"}
      @outbuf[p]=[] unless Array === @outbuf[p]
      @outbuf[p].push(stm)
    }
  end

  # Internal command
  private
  def delay
    Thread.new{
      Thread.pass
      loop{
        p=@proc.shift
        dl=Time.now+@wait
        while @wait
          sleep 1
          if p.call || dl < Time.now
            flush
            break
          end
        end
      }
    }
  end

  def flush
    unless @inbuf.empty?
      @issue=true
      @wait=nil
      @inbuf.each{|c| @q.push(c) }
      @v.msg{"MAIN:Flushed #{@inbuf}"}
      @inbuf.clear
    end
    self
  end
end
