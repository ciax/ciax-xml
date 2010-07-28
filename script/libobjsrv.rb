#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv < Hash

  def initialize(obj)
    @odb=Obj.new(obj)
    update({:cmd=>'upd',:int=>'10',:obj => obj,:issue =>''})
    update(@odb)
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
    prom << self[:obj]
    prom << self[:issue]
    prom << ">"
  end

  def dispatch(line)
    resp=@errmsg.shift
    return resp if resp
    return '' if line.empty?
    cmdary=line.split(' ')
    case cmdary.shift
    when 'stat'
      yield @odb['stat']
    when 'auto'
      auto_upd(cmdary)
    when 'save'
      @ddb.save(cmdary.shift)
      yield @odb['stat']
    when 'load'
      @odb.get_stat(@ddb.load(cmdary.shift))
      yield @odb['stat']
    else
      begin
        session(line)
      rescue
        msg=[$!.to_s]
        msg << "== Internal Command =="
        msg << " stat\t:Show Status"
        msg << " auto ?\t:Auto Update (opt)"
        msg << " save ?\t:Save Field (tag)"
        msg << " load ?\t:Load Field (tag)"
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
    @odb.objcom {|a| @q.push(a)}
    "Accepted\n"
  end

  def device_thread
    Thread.new {
      loop {
        cmdary=@q.shift
        self[:issue]='*'
        begin
          @ddb.setcmd(cmdary)
          @ddb.devcom
          @odb.get_stat(@ddb.field)
        rescue
          @errmsg << e2s
        ensure
          self[:issue]=''
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
              self[:cmd].split(';').each {|c| session(c)} if @q.empty?
              sleep self[:int].to_i
            }
          rescue
            @errmsg << e2s
          end
        }
      when /^int=/
        num=$'
        if num.to_i > 0
          self[:int]=num
        else
          str << "Out of Range\n" 
        end
      when /^cmd=/
        line=$'
        line.split(";").each{|c| @odb.setcmd(c)}
        self[:cmd]=line
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
    str << "Running(cmd=[#{self[:cmd]}] int=[#{self[:int]}])\n"
  end

  def e2s
    msg=$!.to_s+"\n"
    msg << $@.to_s+"\n" if ENV['VER']
  end
end
