#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcl"

class McrSub < Array
  @@client={}
  attr_reader :stat
  def initialize(par,test=nil)
    @v=Msg::Ver.new("mcr",9)
    Msg.type?(par,Param)
    #Thread.abort_on_exception=true
    @test=test
    @interval=test ? 0 : 1
    @seq=0
    @stat='run'
    submacro(par,0)
  end

  def submacro(par,depth)
    par[:select].each{|e1|
      push({'cid'=>par[:cid],'seq' => @seq,'depth'=>depth})
      last.update(e1)
      @seq+=1
      case e1['type']
      when 'break'
        judge("Proceed?",e1) && break
      when 'check'
        judge("Check",e1) || !ENV['ACT'] || raise(UserError)
      when 'wait'
        judge("Waiting",e1) || !ENV['ACT'] || raise(UserError)
      when 'mcr'
        sp=par.dup.set(e1['cmd'])
        if /true|1/ === e1['async']
          yield sp
        else
          submacro(sp,depth+1)
        end
      when 'exec'
        query
        if ENV['ACT']
          @@client[e1['ins']].upd(e1['cmd'])
          @@client.each{|k,v| v.view.refresh }
        end
      end
    }
    self
  end

  def to_s
    Msg.view_struct(self)
  end

  private
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
        c.any?{|h| condition(h)} && break
      elsif c=e['all']
        c.all?{|h| condition(h)} && break
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
  def getstat(ins,id)
    @@client[ins]||=AppCl.new(ins,('localhost' if @test))
    view=@@client[ins].view.load
    if last['update']=view.update?
      view['msg'][id]||view['stat'][id]
    end
  end

  def sleep(n=nil)
    return n if @test
    if n
      Kernel.sleep n
    else
      Kernel.sleep
    end
  end
end

if __FILE__ == $0
  require "optparse"
  require "libmcrdb"
  require "libmcrprt"

  opt=ARGV.getopts("rt")
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id)
    par=Param.new(mdb).set(cmd)
    mcr=McrSub.new(par,opt['t'])
    mcr.extend(McrPrt) unless opt['r']
    puts mcr.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} (-rt) [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
