#!/usr/bin/ruby
require "thread"

class ClsAuto
  attr_reader :auto

  def initialize(queue)
    @cmd='upd'
    @int=10
    @q=queue
    @errmsg=Array.new
    @auto=Thread.new {
      Thread.stop
      begin
        loop{
          @cmd.split(',').each {|s|
            @q.push(s)
          }
          sleep @int
        }
      rescue
        @errmsg << $!.to_s
        Thread.stop
      end
    }
  end

  def active?
    ! @auto.stop?
  end

  def auto_upd(stm)
    par=stm.dup
    if par.shift != 'auto'
      msg=[$!.to_s]
      msg << "== Internal Command =="
      msg << " auto ?    : Auto Update (opt)"
      raise SelectID,msg.compact.join("\n")
    end
    case par.shift
    when 'stat'
      str=["Running(cmd=[#{@cmd}] int=[#{@int}])"]
      str.unshift("Not") if @auto.stop?
      str << @errmsg
      str.join(' ')
    when 'start'
      @auto.run
    when 'stop'
      @auto.raise "Stopped"
      sleep 0.1
    when /^int=/
      num=$'.to_i
      if num > 0
        @int=num
      else
        raise "Out of Range"
      end
    when /^cmd=/
      line=$'
      begin
        line.split(',').each { |s|
          yield(s.split(':'))
        }
        @cmd=line
      rescue SelectID
        msg=["Invalid Command"]
        msg << $!.to_s
      end
    else
      msg=["Usage: auto [opt]"]
      msg << " stat       : Auto update Status"
      msg << " start      : Start Auto update"
      msg << " stop       : Stop Auto update"
      msg << " cmd=       : Set Commands (cmd:par,...)"
      msg << " int=       : Set Interval (sec)"
      raise SelectID,msg.join("\n")
    end
  end
end
