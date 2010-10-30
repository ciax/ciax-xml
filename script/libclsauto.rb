#!/usr/bin/ruby
require "thread"

class ClsAuto
  attr_reader :active

  def initialize(queue)
    @cmd='upd'
    @int=10
    @q=queue
    @errmsg=Array.new
    @active=nil
    @auto=Thread.new {
      loop{
        sleep @int
        if @active && @q.empty?
          begin
            @cmd.split(',').each {|s|
              @q.push(s.split(':'))
            }
          rescue
            @errmsg << $!.to_s
          end
        end
      }
    }
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
      str= @active ? ["Active"] : ["Inactive"]
      str << "(cmd=[#{@cmd}] int=[#{@int}])"
      str << @errmsg
      str.join(' ')
    when 'start'
      @active=true
    when 'stop'
      @active=nil
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
