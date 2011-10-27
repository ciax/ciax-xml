#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "librview"

class McrMan
  attr_reader :prompt
  def initialize(id)
    @par=Param.new(McrDb.new(id))
    @view=[]
    @prompt="#{id}>"
    @id=id
    @current=nil
  end

  def exec(cmd)
    threads=Thread.list
    case cmd[0]
    when nil
      return self
    when 'list'
      raise UserError,"#{Thread.list}"
    when /^[0-9]+$/ && threads.size > cmd[0].to_i
      @current=threads[cmd[0].to_i]
    else
      @current=McrThrd.new(@view,@par.set(cmd))
    end
    @prompt.replace(@id+':'+@current.prompt)
    self
  end

  def to_s
    @current.to_s
  end
end

class McrThrd < Thread
  attr_reader :prompt
  def initialize(view,par,int=1)
    @v=Msg::Ver.new("mcr",9)
    Msg.type?(par,Param)
    @int=int
    @ind=0
    @line=[]
    @msg=[]
    @view=view
    @prompt='mcr>'
    super(par.dup){|par|submcr(par)}
  end

  def submcr(par)
    mtitle(par[:cmd])
    @ind+=1
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
          submcr(sp)
        else
          submcr(sp)
        end
      when 'exec'
        @view.each{|k,v| v.refresh }
        title(e1['cmd'],e1['ins'])
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

  private
  def mtitle(cmd,stat=nil)
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

  def judge(msg,e)
    @line << "  "*@ind+Msg.color(msg,6)+":#{e['label']} "
    @msg.clear
    (e['retry']||1).to_i.times{|n|
      sleep @int if n > 0
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
    par=Param.new(mdb).set(cmd)
    puts McrThrd.new({},par,0).run.join.to_s
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
