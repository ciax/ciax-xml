#!/usr/bin/ruby
require "libverbose"
require "thread"

class Buffer
  def initialize
    @inbuf=[[],[],[]]
    @outbuf=[[],[],[]]
    @q=Queue.new
    @v=Verbose.new("BUF")
    @issue=@wait=false
    @proc=Queue.new
    @st=delay
  end

  def send
    stms=yield
    raise "Should be Array of statements" unless Array === stms
    stms.each{|stm|
      @inbuf[1].push(stm)
      @v.msg{"MAIN:Issued [#{stm}] with priority [normal]"}
    }
    flush(1) unless @wait
    self
  end

  def auto
    if @q.empty?
      yield.each{|stm|
        @inbuf[2].push(stm)
      }
      flush(2)
    else
      @v.msg{"MAIN:Rejected [#{stms}] with priority [auto]"}
    end
    self
  end

  def interrupt(cmds=[])
    @v.msg{"MAIN:Stopped"}
    @issue=@wait=false
    @q.clear
    @v.msg{"MAIN:Issued #{cmds}"}
    @inbuf[0]=cmds
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

  # For session thread
  def recv
    @issue=false
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
      @outbuf[p] ||= []
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

  def flush(p)
    unless @inbuf[p].empty?
      @issue=true
      @wait=false
      @inbuf[p].each{|c| @q.push([p,c]) }
      @v.msg{"MAIN:Flushed #{@inbuf[p]}"}
      @inbuf[p]=[]
    end
    self
  end
end
