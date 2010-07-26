#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv < Hash

  def initialize(obj)
    @odb=Obj.new(obj)
    update(@odb)
    update({'cmd'=>'upd','int'=>'10',:obj => obj,:issue =>''})
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
      yield self['stat']
    when 'auto'
      auto_upd(cmdary)
    else
      begin
        session(line)
      rescue
        help
      end
    end
  end
  
  private
  def device_thread
    Thread.new {
      ddb=DevCom.new(self['device'],self['client'],self[:obj])
      @odb.get_stat(ddb.field)
      loop {
        cmdary=@q.shift
        self[:issue]='*'
        begin
          ddb.setcmd(cmdary)
          ddb.devcom
          @odb.get_stat(ddb.field)
        rescue
          @errmsg << e2s
        ensure
          self[:issue]=''
        end
      }
    }
  end

  def session(line)
    return '' if line == ''
    @odb.setcmd(line)
    @odb.objcom {|cmdary|
      @q.push(cmdary)
    }
    "Accepted\n"
  end

  def auto_upd(cmdary)
    cmdary.each { |cmd|
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
              self['cmd'].split(';').each {|c| session(c)} if @q.empty?
              sleep self['int'].to_i
            }
          rescue
            @errmsg << e2s
          end
        }
      when /(cmd|int)=/
        self[$1]=$'
      end
    }
    str = "Running(cmd=[#{self['cmd']}] int=[#{self['int']}])\n"
    str = "Not "+str unless @auto.alive?
    str
  end

  def help
    resp=e2s
    resp << "auto\t:Auto Update "
    resp << "(start | stop | cmd=[upd(;..)] | int=[nn(sec)])\n"
    resp << "stat\t:Show Status\n"
  end

  def e2s
    $!.to_s+"\n"
  end
end
