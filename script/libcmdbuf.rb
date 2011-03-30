#!/usr/bin/ruby
require "libverbose"
require "thread"

class CmdBuf
  def initialize
    @inbuf=Array.new
    @outbuf=Array.new
    @q=Queue.new
    @v=Verbose.new("BUF")
    @wait=@issue=@int=nil
    @proc=Queue.new
    @st=Thread.new{
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

  def send(p=2)
    if p < 2 || @q.empty?
      stms=yield
      raise "Should be Array of statements" unless Array === stms
      stms.each{|stm|
        @inbuf.push([p,stm])
        @v.msg{"MAIN:Issued [#{stm}] with priority [#{p}]"}
      }
      flush unless @wait
    else
      @v.msg{"MAIN:Rejected [#{stms}] with priority [#{p}]"}
    end
    self
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

  def empty?
    @q.empty?
  end

  def interrupt(cmds=[])
    @v.msg{"MAIN:Stopped"}
    @issue=nil
    @q.clear
    @v.msg{"MAIN:Issued #{cmds}"}
    @inbuf.replace(cmds.map!{|c| [0,c]})
    flush
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
  def flush
    @v.msg{"MAIN:Flushing #{@inbuf}"}
    unless @inbuf.empty?
      @issue=true
      @inbuf.each{|c| @q.push(c) }
      @inbuf.clear
      @wait=nil
      @v.msg{"MAIN:Flushed all" }
    end
    self
  end
end
