#!/usr/bin/ruby
require "libcls"
require "libdev"
require "thread"

class ClsSrv

  def initialize(cls,iocmd,obj=nil)
    @cdb=Cls.new(cls,obj)
    @var={:cmd=>'upd',:int=>'10',:cls => cls,:issue =>''}
    @ddb=DevCom.new(@cdb.device,iocmd,obj)
    @cdb.get_stat(@ddb.field)
    @q=Queue.new
    @errmsg=Array.new
    @auto=Thread.new{}
    device_thread
    sleep 0.01
  end

  def prompt
    prom = @auto.alive? ? '&' : ''
    prom << @var[:cls]
    prom << @var[:issue]
    prom << ">"
  end

  def dispatch(stm)
    return '' if stm.empty?
    if resp=@errmsg.shift
      return resp
    end
    begin
      @cdb.session(stm) {|cmd| @q.push(cmd)}
      "Accepted"
    rescue SelectID
      case stm.shift
      when 'stat'
        yield @cdb.stat
      when 'auto'
        auto_upd(stm)
      else
        msg=[$!.to_s]
        msg << "== Internal Command =="
        msg << " stat      : Show Status"
        msg << " auto ?    : Auto Update (opt)"
        raise SelectID,msg.join("\n")
      end
    end
  rescue
    e2s
  end

  private
  def device_thread
    Thread.new {
      loop {
        stm=@q.shift
        @var[:issue]='*'
        begin
          @ddb.devcom(stm)
          @cdb.get_stat(@ddb.field)
        rescue
          @errmsg << e2s
        ensure
          @var[:issue]=''
        end
      }
    }
  end

  def auto_upd(stm)
    stm.each { |cmd|
      case cmd
      when 'stop'
        if @auto
          @auto.kill
          sleep 0.1
        end
      when 'start'
        @auto.kill if @auto
        @auto=Thread.new {
          begin
            loop{
              if @q.empty?
                @var[:cmd].split(';').each { |s|
                  @cdb.session(s.split(':')){ |cmd| @q.push(cmd) }
                } 
              end
              sleep @var[:int].to_i
            }
          rescue
            @errmsg << e2s
          end
        }
      when /^int=/
        num=$'
        if num.to_i > 0
          @var[:int]=num
        else
          raise "Out of Range"
        end
      when /^cmd=/
        line=$'
        line.split(";").each{|c| @cdb.setcmd(c)}
        @var[:cmd]=line
      else
        msg=["== option list =="]
        msg << " start      : Start Auto update"
        msg << " stop       : Stop Auto update"
        msg << " cmd=       : Set Commands (cmd:par;..)"
        msg << " int=       : Set Interval (sec)"
        raise SelectID,msg.join("\n")
      end
    }
    str=["Running(cmd=[#{@var[:cmd]}] int=[#{@var[:int]}])"]
    str.unshift("Not") unless @auto.alive?
    str.join(' ')
  end

  def e2s
    msg=[$!.to_s]
    msg << $@.to_s if ENV['VER']
    msg.join("\n")
  end
end
