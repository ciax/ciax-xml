#!/usr/bin/ruby
require "thread"

class ClsBuf < Array
  def initialize(queue)
    @q=queue
    @wait=nil
    @proc=Queue.new
    @st=Thread.new{
      loop{
        @proc.shift.call
        flush
      }
    }
  end

  def issue(cmd)
    push(cmd)
    return if @wait
    flush
  end

  def wait # Need Block
    @wait=1
    @proc.push(proc)
  end

  def wait?
    @wait
  end

  def interrupt(cmds)
    replace(cmds)
    flush
    @st.run if @st.stop?
  end

  private
  def flush
    while c=shift
      @q.push(c)
    end
    @wait=nil
  end
end
