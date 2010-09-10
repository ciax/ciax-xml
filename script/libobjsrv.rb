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
    when 'field'
      field(cmdary)
    when 'auto'
      auto_upd(cmdary)
    when 'save'
      @ddb.save(*cmdary)
    when 'load'
      yield @odb.get_stat(@ddb.load(*cmdary))
    else
      session(line)
    end
  rescue
    e2s
  end
  
  private
  def session(line)
    return '' if line == ''
    @odb.setcmd(line)
    @odb.objcom {|cmd| @q.push(cmd)}
    "Accepted"
  rescue
    msg=[$!.to_s]
    msg << "== Internal Command =="
    msg << " stat      : Show Status"
    msg << " field ?   : Field (opt)"
    msg << " auto ?    : Auto Update (opt)"
    msg << " save ?    : Save Field [var] (tag)"
    msg << " load ?    : Load Field [var] (tag)"
    raise msg.join("\n")
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

  def field(cmds)
    cmds.each{ |cmd|
      key,val=cmd.split('=')
      h=@ddb.field
      key.split(':').each{|i|
        i=i.to_i if Array === h
        raise "No such var [#{i}]" unless h[i]
        h=h[i]
      }
      h.replace(val) if val
      return "#{key} = #{h}"
    }
    msg=["== option list =="]
    msg << " key:(num)  : Show Value"
    msg << " key:(num)= : Set Value"
    msg << " key=#{@ddb.field.keys}"
    raise msg.join("\n")
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
          raise "Out of Range"
        end
      when /^cmd=/
        line=$'
        line.split(";").each{|c| @odb.setcmd(c)}
        @var[:cmd]=line
      else
        msg=["== option list =="]
        msg << " start      : Start Auto update"
        msg << " stop       : Stop Auto update"
        msg << " cmd=       : Set Commands (cmd;..)"
        msg << " int=       : Set Interval (sec)"
        raise msg.join("\n")
      end
    }
    str << "Not " unless @auto.alive?
    str << "Running(cmd=[#{@var[:cmd]}] int=[#{@var[:int]}])"
  end

  def e2s
    msg=[$!.to_s]
    msg << $@.to_s if ENV['VER']
    msg.join("\n")
  end
end
