#!/usr/bin/ruby
require "thread"

class ClsAuto
  attr_reader :auto

  def initialize(fi=nil,fo=nil)
    @cmd='upd'
    @int=10
    @errmsg=Array.new
    @auto=Thread.new{}
    @fi=fi || proc{|s|s}
    @fo=fo || proc{|s|s}
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
      str.unshift("Not") unless @auto.alive?
      str << @errmsg
      str.join(' ')
    when 'start'
      @auto.kill if @auto
      @auto=Thread.new {
        begin
          loop{
            @cmd.split(',').each {|s|
              yield(@fi.call(s.split(':')),@fo)
            }
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
          yield(@fi.call(s.split(':')),proc{|c|c})
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
