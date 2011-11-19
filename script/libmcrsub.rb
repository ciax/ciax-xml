#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcl"

module McrPrt
  def to_s
    return '' if empty?
    map{|h|
      msg='  '*h['depth']
      case h['type']
      when 'break'
        msg << Msg.color('Proceed?',6)+":#{h['label']} ->"
        msg << Msg.color(h['result'] ? "SKIP" : "OK",2)
      when 'check'
        msg << Msg.color('Check',6)+":#{h['label']} ->"
        if h['result']
          msg << Msg.color("OK",2)
        else
          msg << Msg.color("NG",1)+"\n"
          msg << getcond(h)
        end
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{h['label']} ->"
        case h['result']
        when nil
          ret=h['retry'].to_i
          msg << '*'*(ret/10)+'.'*(ret % 10)
        when false
          msg << Msg.color("Timeout(#{h['retry']})",1)
        else
          msg << Msg.color("OK",2)
        end
      when 'mcr'
        msg << Msg.color("MACRO",3)+":#{h['cmd'].join(' ')}"
        msg << "(async)" if h['async']
      when 'exec'
        msg << Msg.color("EXEC",13)+":#{h['cmd'].join(' ')}(#{h['ins']})"
      end
      msg
    }.join("\n")
  end

  private
  def getcond(h)
    msg='  '*(h['depth']+1)
    c=h['all'].last
    msg << Msg.color("#{c['ins']}:#{c['ref']}",3)+" is not #{c['val']}"
  end
end

class McrSub < Array
  @@client={}
  def initialize(par,interval=1)
    @v=Msg::Ver.new("mcr",9)
    Msg.type?(par,Param)
    #Thread.abort_on_exception=true
    @interval=interval
    @seq=0
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
    return if @interval == 0
    self[:stat]="wait"
    sleep
    self[:stat]="run"
  end

  def judge(msg,e)
    last['result']=(e['retry']||1).to_i.times{|n|
      sleep @interval if n > 0
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
    @@client[ins]||=AppCl.new(ins,'localhost')
    view=@@client[ins].view.load
    if last['update']=view.update?
      view['msg'][id]||view['stat'][id]
    end
  end
end

if __FILE__ == $0
  require "libmcrdb"
  require "optparse"

  opt=ARGV.getopts("v")
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id)
    par=Param.new(mdb).set(cmd)
    mcr=McrSub.new(par,0)
    mcr.extend(McrPrt) if opt['v']
    puts mcr.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} (-v) [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
