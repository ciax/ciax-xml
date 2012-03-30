#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libintapps"

class Broken < RuntimeError;end

class McrSub < Array
  ACT=ENV['ACT'].to_i
  @@client=IntApps.new

  def initialize(cobj,int=nil)
    @v=Msg::Ver.new(self,9)
    @int=int
    @cobj=Msg.type?(cobj,Command)
    @line=[]
  end

  def macro(cmd)
    cobj=@cobj.dup.set(cmd)
    @line.clear
    #Thread.abort_on_exception=true
    push Thread.new(cobj){|c|
      crnt=Thread.current
      crnt[:obj]=self
      crnt[:tid]=Time.now.to_i
      crnt[:cid]=c[:cid]
      begin
        crnt[:stat]='run'
        submacro(c,1)
        crnt[:stat]='done'
      rescue UserError
        crnt[:stat]="error"
      rescue Broken
        crnt[:stat]="broken"
      end
    }
    self
  end

  def to_s
    Msg.view_struct(@line)
  end

  def join
    each{|t| t.join}
  end

  private
  def submacro(cobj,depth,ins=nil)
    cobj[:select].each{|e1|
      @last={'tid'=>Thread.current[:tid],'cid'=>cobj[:cid],'depth'=>depth}
      @line.push(@last)
      @last.update(e1).delete('stat')
      case e1['type']
      when 'break'
        !fault?(e1,ins) && ENV['ACT'] && break
      when 'check'
        fault?(e1,ins) && ENV['ACT'] && raise(UserError)
      when 'wait'
        if e1['retry'].to_i.times{|n|
          sleep 1 if ACT > 0 && n > 0
          @last['retry']=n
          fault?(e1,ins) || break
        }
          @last['timeout']=true
          ENV['ACT'] && raise(UserError)
        else
          @last.delete('fault')
        end
      when 'mcr'
        if /true|1/ === e1['async']
          clone.clear.macro(e1['cmd'])
        else
          subc=cobj.dup.set(e1['cmd'])
          submacro(subc,depth+1,e1['ins']||ins)
        end
      when 'exec'
        exe(e1['cmd'],e1['ins']||ins)
      end
    }
    self
  end

  def fault?(e,ins)
    flt={}
    !e['stat'].all?{|h|
      flt['ins']=h['ins']||ins
      break unless flt['upd']=update?(flt['ins'])
      ['var','val','inv'].each{|k| flt[k]=h[k] }
      if res=getstat(flt['ins'],flt['var'])
        flt['res']=res
        flt['upd'] && comp(res,flt['val'],flt['inv'])
      end
    } && @last['fault']=flt
  end

  # client is forced to be localhost
  def update?(ins)
    if @@client.key?(ins)
      view=@@client[ins].view.load
    else
      case ACT
      when 0
        int=@@client.add(ins,{'t'=>1})
      when 1
        int=@@client.add(ins,{'d'=>1})
      else
        int=@@client
      end
      view=int[ins].view.load
    end
    view.update?
  end

  def getstat(ins,var)
    view=@@client[ins].view
    res=view['msg'][var]||view['stat'][var]
    @v.msg{"ins=#{ins},var=#{var},res=#{res}"}
    @v.msg{view['stat']}
    res
  end

  def exe(cmd,ins)
    Thread.current[:stat]="wait"
    sleep if @int
    Thread.current[:stat]="run"
    @@client.each{|k,v| v.view.refresh }
    @@client[ins].exe(cmd)
  end

  def comp(res,val,inv)
    i=(/true|1/ === inv)
    if /[a-zA-Z]/ === val
      (/#{val}/ === res) ^ i
    else
      (val == res) ^ i
    end
  end
end

if __FILE__ == $0
  require "optparse"
  require "libmcrdb"
  require "libmcrprt"

  opt=ARGV.getopts("r")
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id)
    cobj=Command.new(mdb[:macro])
    mcr=McrSub.new(cobj)
    mcr.extend(McrPrt) unless opt['r']
    mcr.macro(cmd).join
    puts mcr.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    Msg.usage("(-r) [mcr] [cmd] (par)","-r:print raw data")
  rescue UserError
    Msg.exit(3)
  end
end
