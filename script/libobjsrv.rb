#!/usr/bin/ruby
require "libobj"
require "libdev"
require "thread"

class ObjSrv
  attr_reader :issue,:auto

  def initialize(obj)
    @odb=Obj.new(obj)
    @obj=obj
    @env={'cmd'=>'upd','int'=>'10'}
    @q=Queue.new
    @issue=nil
    @errmsg=Array.new
    @auto=Thread.new{}
    Thread.new {
      ddb=DevCom.new(@odb['device'],@odb['client'],obj)
      @odb.get_stat(ddb.field)
      loop {
        cmdary=@q.shift
        @issue=true
        begin
          ddb.setcmd(cmdary)
          ddb.devcom
          @odb.get_stat(ddb.field)
        rescue
          @errmsg << $!.to_s+"\n"
        ensure
          @issue=nil
        end
      }
    }
    sleep 0.01
  end
  
  def server
    @odb['server']
  end

  def prompt
    prom="#{@obj}"
    prom << '&' if @auto.alive?
    prom << '*' if @issue
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
      auto_upd(cmdary.shift)
    else
      begin
        session(line)
      rescue
        resp=$!.to_s+"\n"
        resp << "auto\t:Auto Update (start|stop|cmd=|int=)\n"
        resp << "stat\t:Show Status\n"
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

  def auto_upd(cmd)
    case cmd
    when 'stop'
      @auto.kill if @auto
    when 'start'
      @auto.kill if @auto
      @auto=Thread.new {
        begin
          loop{
            if @q.empty?
              @env['cmd'].split(';').each { |cmd|
                session(cmd)
              }
            end
            sleep @env['int'].to_i
          }
        rescue
          @errmsg << $!.to_s+"\n"
        end
      }
    when /(cmd|int)=/
      @env[$1]=$'
    end
    str="Auto Update:"
    str << "Not " unless @auto.alive?
    str << "Running\ncmd=[#{@env['cmd']}] int=[#{@env['int']}]\n"
  end

end
