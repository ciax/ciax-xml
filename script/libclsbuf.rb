#!/usr/bin/ruby
require "libverbose"
require "thread"

class ClsBuf < Array
  def initialize(queue)
    @q=queue
    @v=Verbose.new("BUF")
    @wait=@issue=nil
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

  def push(cmd)
    super
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
    @issue=nil
    @q.clear
    replace(cmds)
    flush
  end

  # For session thread
  def recv
    @issue=nil
    @v.msg{"Complete"}
    c=@q.shift
    @v.msg{"Recieve #{c}"}
    c
  end

  private
  def flush
    @v.msg{"Flushing #{self}"}
    while c=shift
      @issue=true
      @q.push(c)
    end
    @wait=nil
    @v.msg{"Sent" }
    self
  end
end
