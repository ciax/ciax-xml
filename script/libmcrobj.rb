#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcl"
require "yaml"

class Broken < RuntimeError;end

class McrObj < Thread
  @@client={}
  @@threads=[]
  attr_reader :line
  def initialize(par,interval=1)
    @v=Msg::Ver.new("mcr",9)
    Msg.type?(par,Param)
    #Thread.abort_on_exception=true
    self[:id]=Time.now.to_i
    @interval=interval
    @depth=0
    @condition=[]
    @line=[]
    self[:line]=[]
    self[:stat]="run"
    self[:cid]=par[:cid]
    super(par.dup){|par|
      begin
        submcr(par)
        self[:stat]="done"
      rescue UserError
        self[:stat]="error"
      rescue Broken
        self[:stat]="broken"
      end
    }
    @@threads << self
  end

  def submcr(par)
    @depth+=1
    par[:select].each{|e1|
      @current={'tid'=>self[:id],'cid'=>par[:cid],'depth'=>@depth}
      @current.update(e1)
      self[:line] << @current
      case e1['type']
      when 'break'
        judge("Proceed?",e1) && break
      when 'check'
        judge("Check",e1) || raise(UserError)
      when 'wait'
        judge("Waiting",e1) || raise(UserError)
      when 'mcr'
        sp=par.dup.set(e1['cmd'])
        if /true|1/ === e1['async']
          McrObj.new(sp)
        else
          submcr(sp)
        end
      when 'exec'
        query
        @@client[e1['ins']].upd(e1['cmd'])
        @@client.each{|k,v| v.view.refresh }
      end
    }
    self
  ensure
    @depth-=1
  end

  def self.threads
    @@threads
  end

  def to_s
    YAML.dump(self[:line])
  end

  private
  def query
    return if @interval == 0
    self[:stat]="wait"
    Thread.stop
    self[:stat]="run"
  end

  def judge(msg,e)
    @current['result']=(e['retry']||1).to_i.times{|n|
      sleep @interval if n > 0
      @current['retry']=n
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
    if @current['update']=view.update?
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
    puts McrObj.new(par,0).run.join.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
