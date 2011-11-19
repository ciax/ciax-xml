#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcl"

class Broken < RuntimeError;end

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

  def getstat(ins,id)
    @@client[ins]||=AppCl.new(ins)
    view=@@client[ins].view.load
    if last['update']=view.update?
      view['msg'][id]||view['stat'][id]
    end
  end
end

if __FILE__ == $0
  require "libmcrdb"
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id)
    par=Param.new(mdb).set(cmd)
    puts McrSub.new(par,0).to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
