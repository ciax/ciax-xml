#!/usr/bin/ruby
require "thread"

class ClsAuto
  attr_reader :active

  def initialize(queue)
    @cmd='upd'
    @int=10
    @q=queue
    $errmsg=''
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
            $errmsg << $!.to_s
          end
        end
      }
    }
  end

  def auto_upd(stm)
    par=stm.dup
    if par.shift != 'auto'
      $errmsg << "== Internal Command ==\n"
      $errmsg << " auto ?    : Auto Update (opt)\n"
      raise SelectID,$errmsg
    end
    case par.shift
    when 'stat'
      str= @active ? ["Active"] : ["Inactive"]
      str << "(cmd=[#{@cmd}] int=[#{@int}])"
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
      $errmsg ="Usage: auto [opt]\n"
      $errmsg << " stat       : Auto update Status\n"
      $errmsg << " start      : Start Auto update\n"
      $errmsg << " stop       : Stop Auto update\n"
      $errmsg << " cmd=       : Set Commands (cmd:par,...)\n"
      $errmsg << " int=       : Set Interval (sec)\n"
      raise SelectID,$errmsg
    end
  end
end
