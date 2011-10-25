#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "librview"

class McrObj
  attr_reader :line
  def initialize(id)
    @v=Msg::Ver.new("mcr",9)
    @mdb=McrDb.new(id)
    @ind=0
    @msg=[]
    @view={}
  end

  def mcr(cmd)
    par=Param.new(@mdb).set(cmd)
    title(cmd,'mcr')
    @ind+=1
    par[:select].each{|e1|
      case e1['type']
      when 'break'
        caption(["Proceed?",":#{e1['label']}"])
        if judge(e1['cond'],par)
          result(-1)
          return self
        end
        result(0)
      when 'check'
        retr=(e1['retry']||1).to_i
        line=[retr > 1 ? "Waiting(#{retr})" : "Check",":#{e1['label']}"]
        caption(line)
        unless judge(e1['cond'],par,retr)
          result(retr)
          return
        end
        result(0)
      when 'mcr'
        cmd=e1['cmd'].map{|v| par.subst(v)}
        mcr(cmd)||return
      when 'exec'
        @view.each{|k,v| v.refresh }
        cmd=e1['cmd'].map{|v| par.subst(v)}
        title(cmd,e1['ins'])
      end
    }
    @ind-=1
    self
  end

  private
  def title(cmd,ins)
    puts "  "*@ind+Msg.color("EXEC",5)+":#{cmd.join(' ')}(#{ins})"
  end

  def caption(msgary)
    print "  "*@ind+Msg.color(msgary.shift,6)+msgary.join('')+" "
  end

  def result(code)
    case code
    when -1
      puts Msg.color("-> SKIP",3)
    when 0
      puts Msg.color("-> OK",2)
    when 1
      puts Msg.color("-> NG",1)
      prtc
    else
      puts Msg.color(" -> Timeout",1)
      prtc
    end
  end

  def prtc
    puts @msg.map{|s| "  "*(@ind+1)+s }.join("\n")
  end

  def judge(conds,par,retr=1)
    @msg.clear
    retr.times{|n|
      sleep 1 if n > 0
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
      print "."
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
    ac=McrObj.new(id)
    ac.mcr(cmd)
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
