#!/usr/bin/ruby
require "libclscmd"
require "thread"

class Auto
  attr_reader :auto

  def initialize(queue,cdb)
    @cmd='upd'
    @int=10
    @q=queue
    @cdb=cdb
    @errmsg=Array.new
    @auto=Thread.new{}
  end

  def auto_upd(stm)
    par=stm.dup
    if par.shift != 'auto'
      msg=[$!.to_s]
      msg << "== Internal Command =="
      msg << " auto ?    : Auto Update (opt)"
      return msg.compact.join("\n")
    end
    case par.shift
    when 'stat'
      str=["Running(cmd=[#{@cmd}] int=[#{@int}])"]
      str.unshift("Not") unless @auto.alive?
      str.join(' ')
    when 'start'
      @auto.kill if @auto
      @auto=Thread.new {
        begin
          loop{
            @cmd.split(',').each {|s|
              @cdb.session((yield s).split(':')){|c| @q.push(c) }
            } if @q.empty?
            sleep @int.to_i
          }
        rescue
          @errmsg << $!.to_s
        end
      }
    when 'stop'
      if @auto
        @auto.kill
        sleep 0.1
      end
    when /^int=/
      num=$'
      if num.to_i > 0
        @int=num
      else
        raise "Out of Range"
      end
    when /^cmd=/
      line=$'
      begin
        line.split(',').each { |s|
          @cdb.session((yield s).split(':')){}
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
      msg.join("\n")
    end
  end
end
