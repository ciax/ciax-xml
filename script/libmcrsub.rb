#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libintapps"

class McrSub < Array
  attr_accessor :stat
  def initialize(mdb,client)
    @v=Msg::Ver.new("mcr",9)
    @par=Param.new(mdb)
    #Thread.abort_on_exception=true
    @client=Msg.type?(client,IntApps)
  end

  def macro(cmd)
    @tid=Time.now.to_i
    @stat='run'
    submacro(cmd){|c| yield c}
    @stat='done'
    self
  end

  def to_s
    Msg.view_struct(self)
  end

  private
  def submacro(cmd)
    @par.push(cmd)[:select].each{|e1|
      line={'tid'=>@tid,'cid'=>@par[:cid],'depth'=>@par.depth}
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
        if /true|1/ === e1['async']
          yield(e1['cmd'])
        else
          submacro(e1['cmd'])
        end
      when 'exec'
        query
        if ENV['ACT']
          @client[e1['ins']].exe(e1['cmd'])
          @client.each{|k,v| v.view.refresh }
        end
      end
    }
    @par.pop
    self
  end

  def query
    @stat="wait"
    sleep
    @stat="run"
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
    view=@client[ins].view.load
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
    @stat='error'
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
    int=IntApps.new
    mcr=McrSub.new(mdb,int)
    mcr.extend(McrPrt) unless opt['r']
    puts mcr.macro(cmd).to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} (-r) [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
