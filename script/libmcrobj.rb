#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "librview"

class Broken < RuntimeError;end

class McrObj < Thread
  @@view={}
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
    mtitle(par[:cmd])
    @depth+=1
    par[:select].each{|e1|
      case e1['type']
      when 'break'
        judge("Proceed?",e1) && (ok("SKIP");break) || ok
      when 'check'
        judge("Check",e1) && ok || ng("NG")
      when 'wait'
        judge("Waiting",e1) && ok || ng("Timeout")
      when 'mcr'
        sp=par.dup.set(e1['cmd'])
        if /true|1/ === e1['async']
          mtitle(e1['cmd'],'async')
          McrObj.new(sp)
        else
          submcr(sp)
        end
      when 'exec'
        @@view.each{|k,v| v.refresh }
        title(e1['cmd'],e1['ins'])
        query
      end
    }
    self
  ensure
    @depth-=1
  end

  def to_s
    self[:line].join("\n")
  end

  def self.threads
    @@threads
  end

  private
  def mtitle(cmd,stat=nil)
    push Msg.color("MACRO",3)+":#{cmd.join(' ')}"
    add "(#{stat})" if stat
  end

  def title(cmd,ins)
    push Msg.color("EXEC",13)+":#{cmd.join(' ')}(#{ins})"
  end

  def ok(str="OK")
    add Msg.color("-> "+str,2)
  end

  def ng(str)
    add Msg.color("-> "+str,1)
    @depth+=1
    pushmsg
    @depth-=1
    raise UserError,to_s
  end

  def query
    return if @interval == 0
    self[:stat]="wait"
    Thread.stop
    self[:stat]="run"
  end

  def judge(msg,e)
    push Msg.color(msg,6)+":#{e['label']} "
    @condition.clear
    (e['retry']||1).to_i.times{|n|
      sleep @interval if n > 0
      if c=e['any']
        c.any?{|h| condition(h)} && break
      elsif c=e['all']
        c.all?{|h| condition(h)} && break
      end
    }.nil?
  end

  def condition(h)
    ins=h['ins']
    key=h['ref']
    inv=/true|1/ === h['inv'] ? '!' : false
    crt=h['val']
    if val=getstat(ins,key)
      waiting("#{ins}:#{key} / #{inv}<#{val}> for [#{crt}]")
      if /[a-zA-Z]/ === crt
        (/#{crt}/ === val) ^ inv
      else
        (crt == val) ^ inv
      end
    else
      waiting("#{ins} status has not been updated")
      false
    end
  end

  def waiting(msg)
    msg=Msg.color(msg,11)
    if @condition.include?(msg)
      add "."
      self[:line].last.gsub!("..........","*")
    else
      @condition << msg
    end
  end

  def getstat(ins,id)
    @@view[ins]||=Rview.new(ins)
    view=@@view[ins].load
    return unless view.update?
    view['msg'][id]||view['stat'][id]
  end

  def push(str)
    @line << stat(str)
    self[:line] << "  "*@depth+str
  end

  def add(str)
    @line.last << str
    self[:line].last << str
  end

  def pushmsg
    @condition.each{|s| stat(s) }
  end

  def stat(str)
    "#{self[:parent]},#{elapse},#{self[:cid]},"+str
  end

  def elapse
    "%.4f" % (Time.now-self[:id]).to_f
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
