#!/usr/bin/ruby
require "thread"

class ClsBuf < Array
  def initialize(queue)
    @q=queue
    @wait=nil
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

  def issue(cmd)
    push(cmd)
    return if @wait
    flush
  end

  def wait_for(timeout=10) # Need Block of boolean
    @wait=timeout.to_i
    @proc.push(proc)
  end

  def wait?
    @wait
  end

  def interrupt(cmds=[])
    replace(cmds)
    flush
  end

  private
  def flush
    while c=shift
      @q.push(c)
    end
    @wait=nil
  end
end
