#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv

  def initialize(obj)
    @odb=Obj.new(obj)
    @env={'cmd'=>'upd','int'=>'10',:obj => obj,:issue =>''}
    @q=Queue.new
    @errmsg=Array.new
    @auto=Thread.new{}
    Thread.new {
      ddb=DevCom.new(@odb['device'],@odb['client'],obj)
      @odb.get_stat(ddb.field)
      loop {
        cmdary=@q.shift
        @env[:issue]='*'
        begin
          ddb.setcmd(cmdary)
          ddb.devcom
          @odb.get_stat(ddb.field)
        rescue
          @errmsg << e2s
        ensure
          @env[:issue]=''
        end
      }
    }
    sleep 0.01
  end
  
  def server
    @odb['server']
  end

  def prompt
    prom = @auto.alive? ? '&' : ''
    prom << @env[:obj]
    prom << @env[:issue]
    prom << ">"
  end

  def dispatch(line)
    resp=@errmsg.shift
    return resp if resp
    cmdary=line.split(' ')
    case cmdary.shift
    when ''
      ''
    when 'stat'
      yield @odb['stat']
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
  def session(line)
    return '' if line == ''
    @odb.objcom(line) {|cmdary|
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
              @env['cmd'].split(';').each {|c| session(c)} if @q.empty?
              sleep @env['int'].to_i
            }
          rescue
            @errmsg << e2s
          end
        }
      when /(cmd|int)=/
        @env[$1]=$'
      end
    }
    str = "Running(cmd=[#{@env['cmd']}] int=[#{@env['int']}])\n"
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
