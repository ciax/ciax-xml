#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
require "libinsdb"
require "librview"

class McrObj
  attr_reader :line
  def initialize(id)
    @v=Msg::Ver.new("mcr",9)
    @par=Param.new(McrDb.new(id))
    @msg=[]
    @view={}
  end

  def exe(cmd)
    @par.set(cmd)
    puts "Exec(MDB):#{@par[:id]}"
    @par[:select].each{|e1|
      case e1
      when Hash
        case e1['type']
        when 'break'
          caption(["Proceed?",":[#{e1['label']}]"],1)
          if judge(e1['cond'])
            puts "  ->  Skip"
            return self
          end
        when 'check'
          retr=(e1['retry']||1).to_i
          line=[retr > 1 ? "Waiting for" : "Check"]
          line << ":#{e1['label']} (#{retr})"
          caption(line,1)
          unless judge(e1['cond'],retr)
            result(retr)
            return self
          end
        end
        result(0)
      else
        puts "  "+Msg.color("EXEC",3)+":#{@par.subst(e1)}"
      end
    }
    self
  end

  private
  def caption(msgary,ind=0)
    puts "  "*ind+Msg.color(msgary.shift,6)+msgary.shift
  end

  def condition(msg)
    if @msg.include?(msg)
      print "."
    else
      @msg << msg
      print msg
    end
  end

  def result(code,ind=1)
    str="\n"+"  "*ind
    case code
    when 0
      str << Msg.color("-> OK",2)
    when 1
      str << Msg.color("-> NG",1)
    else
      str << Msg.color("-> Timeout",1)
    end
    puts str
  end

  def judge(conds,retr=1)
    res=retr.times{|n|
      sleep 1 if n > 0
      conds.all?{|h|
          ins=h['ins']
          key=h['ref']
          crt=@par.subst(h['val'])
          if val=getstat(ins,key)
            condition("   #{ins}:#{key} / <#{val}> for [#{crt}]")
            if /[a-zA-Z]/ === crt
              /#{crt}/ === val
            else
              crt == val
            end
          else
            puts "   #{ins} is not updated"
            false
          end
      } && break
    }.nil?
    @msg.clear
    res
  end

  def getstat(ins,id)
    @view[ins]||=Rview.new(ins)
    view=@view[ins].upd
    return unless view.update?
    view['msg'][id]||view['stat'][id]
  end
end

if __FILE__ == $0
  id,*cmd=ARGV
  ARGV.clear
  begin
    ac=McrObj.new(id)
    ac.exe(cmd)
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
