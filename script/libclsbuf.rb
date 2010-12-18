#!/usr/bin/ruby
require "libverbose"
require "thread"

class ClsBuf < Array
  attr_reader :level

  def initialize
    @q=Queue.new
    @v=Verbose.new("BUF")
    @wait=@issue=@int=nil
    @level=0
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

  def push(cmd,level=0)
    super(cmd)
    @level=level
    @v.msg{"Issued"}
    flush unless @wait
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

  def interrupt(cmds=[])
    @v.msg{"Stopped"}
    @issue=nil
    @level=2
    @q.clear
    replace(cmds)
    flush
  end

  # For session thread
  def recv
    @issue=nil
    @v.msg{"Waiting"}
    c=@q.shift
    @v.msg{"Recieve #{c}"}
    l=@level
    @level=0
    [c,l]
  end

  def int?(level)
    if @level > level
      @v.msg{"Cutting in Buffer #{@level} > #{level}"}
      true
    else
      @v.msg{"At the end of Buffer #{@level} <= #{level}" }
      false
    end
  end

  # Internal command
  private
  def flush
    @v.msg{"Flushing #{self}"}
    while c=shift
      @issue=true
      @q.push(c)
    end
    @wait=nil
    @v.msg{"Sent all" }
    self
  end
end
