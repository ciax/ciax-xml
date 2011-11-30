#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libintapps"

class Broken < RuntimeError;end

class McrSub < Array
  @@client=IntApps.new

  def initialize(cobj,threads=[])
    @v=Msg::Ver.new("mcr",9)
    Msg.type?(cobj,Command)
    @threads=Msg.type?(threads,Array)
    #Thread.abort_on_exception=true
    @current=Thread.current
    @threads << @current
    @current[:obj]=self
    Thread.pass
    @tid=Time.now.to_i
    @current[:cid]=cobj[:cid]
    @current[:stat]='run'
    submacro(cobj.dup,1)
    @current[:stat]='done'
  rescue UserError
    @current[:stat]="error"
  rescue Broken
    @current[:stat]="broken"
  end

  def to_s
    Msg.view_struct(self)
  end

  private
  def submacro(cobj,depth)
    cobj[:select].each{|e1|
      line={'tid'=>@tid,'cid'=>cobj[:cid],'depth'=>depth}
      line.update(e1)
      push(line)
      case e1['type']
      when 'break'
        judge("Proceed?",e1) && break
      when 'check'
        judge("Check",e1) || error
      when 'wait'
        judge("Waiting",e1) || error
      when 'mcr'
        subc=cobj.dup.set(e1['cmd'])
        if /true|1/ === e1['async']
          Thread.new(subc,@threads){|c,tary|
            McrSub.new(c,tary)
          }
        else
          submacro(subc,depth+1)
        end
      when 'exec'
        query
        if ENV['ACT'].to_i > 1
          @@client[e1['ins']].exe(e1['cmd'])
          @@client.each{|k,v| v.view.refresh }
        end
      end
    }
    self
  end

  def query
    @current[:stat]="wait"
    sleep
    @current[:stat]="run"
  end

  def judge(msg,e)
    last['result']=(e['retry']||1).to_i.times{|n|
      sleep 1 if n > 0
      last['retry']=n
      if c=e['any']
        c.any?{|h| h['res']=condition(h)} && break
      elsif c=e['all']
        c.all?{|h| h['res']=condition(h)} && break
      end
    }.nil?
  end

  def condition(h)
    inv=/true|1/ === h['inv'] ? '!' : false
    crt=h['val']
    if val=getstat(h['ins'],h['ref'])
      if /[a-zA-Z]/ === crt
        (/#{crt}/ === val) ^ inv
      else
        (crt == val) ^ inv
      end
    end
  end

  # client is forced to be localhost
  def getstat(ins,ref)
    view=@@client[ins].view.load
    if last['update']=view.update?
      view['msg'][ref]||view['stat'][ref]
    end
  end

  def sleep(n=nil)
    return n unless ENV['ACT']
    if n
      Kernel.sleep n
    else
      Kernel.sleep
    end
  end

  def error
    return unless ENV['ACT']
    @current[:stat]='error'
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
    cobj=Command.new(mdb).set(cmd)
    mcr=McrSub.new(cobj)
    mcr.extend(McrPrt) unless opt['r']
    puts mcr.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} (-r) [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
