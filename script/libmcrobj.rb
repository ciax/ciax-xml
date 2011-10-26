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
    mtitle(par[:cid],stat)
    @ind+=1
    par[:select].each{|e1|
      case e1['type']
      when 'break'
        caption(["Proceed?",":#{e1['label']}"])
        if judge(e1['cond'],par)
          result(-1)
          break
        else
          result(0)
        end
      when 'check'
        caption(["Check",":#{e1['label']}"])
        if judge(e1['cond'],par)
          result(0)
        else
          result(1)
        end
      when 'wait'
        retr=(e1['retry']||1).to_i
        caption(["Waiting(#{retr})",":#{e1['label']}"])
        if judge(e1['cond'],par,retr)
          result(0)
        else
          result(retr)
        end
      when 'mcr'
        sp=par.dup.set(e1['cmd'].map{|v| par.subst(v)})
        if /true|1/ === e1['async']
          submcr(sp,'async')
        else
          submcr(sp)
        end
      when 'exec'
        @view.each{|k,v| v.refresh }
        sp=par.dup.set(e1['cmd'].map{|v| par.subst(v)})
        title(sp[:cid],e1['ins'])
        @prompt.replace("mcr>Proceed?(Y/N)")
        Thread.stop
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
  def mtitle(cid,stat)
    @line << "  "*@ind+Msg.color("MACRO",5)+":#{cid}"
    @line.last << "(#{stat})" if stat
  end

  def title(cid,ins)
    @line << "  "*@ind+Msg.color("EXEC",5)+":#{cid}(#{ins})"
  end

  def caption(msgary)
    @line << "  "*@ind+Msg.color(msgary.shift,6)+msgary.join('')+" "
  end

  def result(code)
    case code
    when -1
      @line.last << Msg.color("-> SKIP",3)
    when 0
      @line.last << Msg.color("-> OK",2)
    when 1
      @line.last << Msg.color("-> NG",1)
      prtc
    else
      @line.last << Msg.color(" -> Timeout",1)
      prtc
    end
  end

  def prtc
    @msg.each{|s| @line << "  "*(@ind+1)+s }
    raise UserError,@line.join("\n")
  end

  def judge(conds,par,retr=1)
    @msg.clear
    retr.times{|n|
      sleep @int if n > 0
      conds.all?{|h|
        ins=h['ins']
        key=h['ref']
        inv=/true|1/ === h['inv'] ? '!' : false
        crt=par.subst(h['val'])
        if val=getstat(ins,key)
          msg=Msg.color("#{ins}:#{key} / #{inv}<#{val}> for [#{crt}]",11)
          waiting(msg)
          if /[a-zA-Z]/ === crt
            (/#{crt}/ === val) ^ inv
          else
            (crt == val) ^ inv
          end
        else
          waiting(Msg.color("#{ins} is not updated",11))
          false
        end
      } && break
    }.nil?
  end

  def waiting(msg)
    if @msg.include?(msg)
      @line.last << "."
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
    par=Param.new(mdb).set(cmd)
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
