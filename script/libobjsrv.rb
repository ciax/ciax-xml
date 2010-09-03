#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv < Hash
  attr_reader :server

  def initialize(obj)
    @odb=Obj.new(obj)
    @var={:cmd=>'upd',:int=>'10',:obj => obj,:issue =>''}
    @server=@odb['server']
    @ddb=DevCom.new(@odb['device'],@odb['client'],obj)
    @odb.get_stat(@ddb.field)
    @q=Queue.new
    @errmsg=Array.new
    @auto=Thread.new{}
    device_thread
    sleep 0.01
  end

  def prompt
    prom = @auto.alive? ? '&' : ''
    prom << @var[:obj]
    prom << @var[:issue]
    prom << ">"
  end

  def dispatch(line)
    resp=@errmsg.shift
    return resp if resp
    return '' if line.empty?
    cmdary=line.split(' ')
    case cmdary.shift
    when 'stat'
      yield @odb.stat
    when 'auto'
      auto_upd(cmdary)
    when 'save'
      @ddb.save(cmdary.shift)
      yield @odb.stat
    when 'load'
      @odb.get_stat(@ddb.load(cmdary.shift))
      yield @odb.stat
    else
      begin
        session(line)
      rescue
        msg=[$!.to_s]
        msg << "== Internal Command =="
        msg << " stat      : Show Status"
        msg << " auto ?    : Auto Update (opt)"
        msg << " save ?    : Save Field (tag)"
        msg << " load ?    : Load Field (tag)"
        raise msg.join("\n")
      end
    end
  rescue
    e2s
  end
  
  private
  def session(line)
    return '' if line == ''
    @odb.setcmd(line)
    @odb.objcom {|cmd| @q.push(cmd)}
    "Accepted\n"
  end

  def device_thread
    Thread.new {
      loop {
        cmd=@q.shift
        @var[:issue]='*'
        begin
          @ddb.setcmd(cmd)
          @ddb.devcom
          @odb.get_stat(@ddb.field)
        rescue
          @errmsg << e2s
        ensure
          @var[:issue]=''
        end
      }
    }
  end

  def auto_upd(cmds)
    str=''
    cmds.each { |cmd|
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
              @var[:cmd].split(';').each {|c| session(c)} if @q.empty?
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
          str << "Out of Range\n" 
        end
      when /^cmd=/
        line=$'
        line.split(";").each{|c| @odb.setcmd(c)}
        @var[:cmd]=line
      else
        msg=["== option list =="]
        msg << " start\t:Start Auto update"
        msg << " stop\t:Stop Auto update"
        msg << " cmd=\t:Set Commands (cmd;..)"
        msg << " int=\t:Set Interval (sec)"
        raise msg.join("\n")
      end
    }
    str << "Not " unless @auto.alive?
    str << "Running(cmd=[#{@var[:cmd]}] int=[#{@var[:int]}])\n"
  end

  def e2s
    msg=$!.to_s+"\n"
    msg << $@.to_s+"\n" if ENV['VER']
    msg
  end
end
