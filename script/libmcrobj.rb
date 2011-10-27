#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "librview"

class McrObj
  attr_reader :prompt
  def initialize(int=1)
    @v=Msg::Ver.new("mcr",9)
    @int=int
    @ind=0
    @line=[]
    @msg=[]
    @view={}
    @threads=[]
    @prompt='mcr>'
  end

  def mcr(par)
    @line.clear
    @threads << Thread.new{
      Thread.pass
      submcr(par)
    }
    self
  end

  def submcr(par,stat=nil)
    mtitle(par[:cmd],stat)
    @ind+=1
    par[:select].each{|e1|
      case e1['type']
      when 'break'
        judge("Proceed?",e1,par) && (ok("SKIP");break) || ok
      when 'check'
        judge("Check",e1,par) && ok || ng("NG")
      when 'wait'
        judge("Waiting",e1,par) && ok || ng("Timeout")
      when 'mcr'
        sp=par.dup.set(e1['cmd'].map{|v| par.subst(v)})
        if /true|1/ === e1['async']
          submcr(sp,'async')
        else
          submcr(sp)
        end
      when 'exec'
        @view.each{|k,v| v.refresh }
        cmd=e1['cmd'].map{|v| par.subst(v)}
        title(cmd,e1['ins'])
        @prompt.replace("mcr>Proceed?(Y/N)")
        Thread.stop if @int > 0
      end
    }
    self
  ensure
    @ind-=1
  end

  def to_s
    @line.join("\n")
  end

  def join
    @threads.select!{|t| t.alive?}
    @threads.each{|t| t.join}
    self
  end

  def proceed
    @threads.select!{|t| t.alive?}
    @threads.each{|t| t.run}
    @prompt.replace "mcr>"
    self
  end

  private
  def mtitle(cmd,stat)
    @line << "  "*@ind+Msg.color("MACRO",3)+":#{cmd.join(' ')}"
    @line.last << "(#{stat})" if stat
  end

  def title(cmd,ins)
    @line << "  "*@ind+Msg.color("EXEC",13)+":#{cmd.join(' ')}(#{ins})"
  end

  def ok(str="OK")
    @line.last << Msg.color("-> "+str,2)
  end

  def ng(str)
    @line.last << Msg.color("-> "+str,1)
    @msg.each{|s| @line << "  "*(@ind+1)+s }
    raise UserError,@line.join("\n")
  end

  def judge(msg,e,par)
    @line << "  "*@ind+Msg.color(msg,6)+":#{e['label']} "
    @msg.clear
    (e['retry']||1).to_i.times{|n|
      sleep @int if n > 0
      if c=e['any']
        c.any?{|h| condition(h,par)} && break
      elsif c=e['all']
        c.all?{|h| condition(h,par)} && break
      end
    }.nil?
  end

  def condition(h,par)
    ins=h['ins']
    key=h['ref']
    inv=/true|1/ === h['inv'] ? '!' : false
    crt=par.subst(h['val'])
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
    if @msg.include?(msg)
      @line.last << "."
      @line.last.gsub!("..........","*")
    else
      @msg << msg
    end
  end

  def getstat(ins,id)
    @view[ins]||=Rview.new(ins)
    view=@view[ins].load
    return unless view.update?
    view['msg'][id]||view['stat'][id]
  end
end

if __FILE__ == $0
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id)
    ac=McrObj.new(0)
    puts par=Param.new(mdb).set(cmd)
    puts ac.mcr(par).proceed.join.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
