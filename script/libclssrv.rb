#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"

class ClsSrv

  def initialize(cls,id,iocmd)
    cdb=XmlDoc.new('cdb',cls)
    @cdbc=ClsCmd.new(cdb)
    @cdbs=ClsStat.new(cdb,id)
    @var={:cmd=>'upd',:int=>'10',:cls => cls,:issue =>''}
    @ddb=Dev.new(cdb['device'],id,iocmd)
    @cdbs.get_stat(@ddb.field)
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
      @cdbc.session(stm) {|cmd| @q.push(cmd)}
      "Accepted"
    rescue SelectID
      case stm.shift
      when 'stat'
        yield @cdbs.stat
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
          @cdbs.get_stat(@ddb.field)
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
                setcmd(@var[:cmd]){|c| @q.push(c) }
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
        setcmd(line){}
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

  def setcmd(line)
    line.split(';').each { |s|
      @cdbc.session(s.split(':')){ |cmd| yield cmd }
    }
  end

  def e2s
    msg=[$!.to_s]
    msg << $@.to_s if ENV['VER']
    msg.join("\n")
  end
end
