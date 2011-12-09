#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libintapps"

class Broken < RuntimeError;end

class McrSub < Array
  ACT=ENV['ACT'].to_i
  @@client=IntApps.new

  def initialize(cobj,threads=[])
    @v=Msg::Ver.new(self,9)
    @cobj=Msg.type?(cobj,Command)
    @threads=Msg.type?(threads,Array)
  end

  def macro(cmd,clr=nil)
    cobj=@cobj.dup.set(cmd)
    @threads.clear if clr
    clear
    #Thread.abort_on_exception=true
    @threads << Thread.new(cobj){|c|
      @crnt=Thread.current
      @crnt[:obj]=self
      @tid=Time.now.to_i
      @crnt[:cid]=c[:cid]
      begin
        @crnt[:stat]='run'
        submacro(c,1)
        @crnt[:stat]='done'
      rescue UserError
        @crnt[:stat]="error"
      rescue Broken
        @crnt[:stat]="broken"
      end
    }
    self
  end

  def to_s
    Msg.view_struct(self)
  end

  private
  def submacro(cobj,depth,ins=nil)
    cobj[:select].each{|e1|
      line={'tid'=>@tid,'cid'=>cobj[:cid],'depth'=>depth}
      line.update(e1).delete('stat')
      line['ins']||=ins
      push(line)
      case e1['type']
      when 'break'
        judge("Proceed?",e1) && ENV['ACT'] && break
      when 'check'
        judge("Check",e1) || error
      when 'wait'
        judge("Waiting",e1) || error
      when 'mcr'
        if /true|1/ === e1['async']
          clone.clear.macro(e1['cmd'])
        else
          subc=cobj.dup.set(e1['cmd'])
          submacro(subc,depth+1,line['ins'])
        end
      when 'exec'
        exe(e1['cmd'])
      end
    }
    self
  end

  def judge(msg,e)
    last['result']=(e['retry']||1).to_i.times{|n|
      sleep 1 if ACT > 0 && n > 0
      last['retry']=n
      fault={}
      e['stat'].all?{|h|
        ['var','ins','val'].each{|k|
          fault[k]=h[k]||last[k]
        }
        condition(fault)
      } && break
      last['fault']=fault
    }.nil?
  end

  def condition(h)
    inv=/true|1/ === h['inv'] ? '!' : false
    crt=h['val']
    if val=h['res']=getstat(h['ins'],h['var'])
      if /[a-zA-Z]/ === crt
        (/#{crt}/ === val) ^ inv
      else
        (crt == val) ^ inv
      end
    end
  end

  # client is forced to be localhost
  def getstat(ins,var)
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
    if last['update']=view.update?
      view['msg'][var]||view['stat'][var]
    end
  end

  def exe(cmd)
    @crnt[:stat]="wait"
    sleep if ENV['ACT'] && ACT < 3
    @crnt[:stat]="run"
    @@client.each{|k,v| v.view.refresh }
    @@client[last['ins']].exe(cmd)
  end

  def error
    return unless ACT > 1
    raise(UserError)
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
    cobj=Command.new(mdb)
    mcr=McrSub.new(cobj,th=[])
    mcr.extend(McrPrt) unless opt['r']
    mcr.macro(cmd)
    th.each{|t| t.join }
    puts mcr.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    Msg.usage "(-r) [mcr] [cmd] (par)"
  rescue UserError
    Msg.exit(3)
  end
end
