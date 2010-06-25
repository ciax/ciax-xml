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
    @auto=Thread.new{}
    @issue=nil
    @errmsg=Array.new
    Thread.new {
      ddb=DevCom.new(@odb['device'],@odb['client'],obj)
      loop {
        c,p=@q.shift
        @issue=true
        begin
          ddb.setcmd(c,p)
          ddb.devcom
          @odb.get_stat(ddb.field)
        rescue
          @errmsg << $!.to_s+"\n"
        ensure
          @issue=nil
        end
      }
    }
  end
  
  def server
    @odb['server']
  end

  def dispatch(line)
    unless resp=@errmsg.shift
      resp=''
      cmd=line.split(' ')
      case cmd.shift
      when 'stat'
        resp=yield @odb.stat
      when 'auto'
        resp=auto_upd(cmd.shift)
      else
        begin
          resp=session(line)
        rescue
          resp=$!.to_s+"\n"
          resp << "auto\t:Auto Update (start|stop|cmd=|int=)\n"
          resp << "stat\t:Show Status\n"
        end
      end
    end
    resp << '&' if @auto.alive?
    resp << '*' if @issue
    resp << "#{@obj}>"
  end
  
  private
  def session(line)
    return '' if line == ''
    @odb.objcom(line) {|c,p|
      @q.push([c,p])
    }
    "Accepted\n"
  end

  def auto_upd(cmd)
    case cmd
    when 'stop'
      @auto.kill
    when 'start'
      @auto.kill
      @auto=Thread.new {
        begin
          loop{
            session(@env['cmd']) if @q.empty?
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
