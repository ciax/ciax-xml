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

  def send(cmd,p=2)
    @inbuf.push([p,cmd])
    @v.msg{"MAIN:Issued [#{cmd}] with priority [#{p}]"}
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

  def empty?
    @q.empty?
  end

  def interrupt(cmds=[])
    @v.msg{"MAIN:Stopped"}
    @issue=nil
    @q.clear
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
          cmd=c.shift
          @v.msg{"SUB:Exec []#{cmd}]"}
          return cmd
        }
        @v.msg{"SUB:Waiting"}
      end
      p,c=@q.shift
      @v.msg{"SUB:Recieve [#{c}] with priority[#{p}]"}
      if @outbuf[p]
        @outbuf[p].push(c)
      else
        @outbuf[p]=[c]
      end
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
