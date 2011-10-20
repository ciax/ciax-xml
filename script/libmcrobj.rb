#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libparam"
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
    puts Msg.color("Exec(MDB):#{@par[:id]}",5)
    @par[:select].each{|e1|
      case e1
      when Hash
        case e1['type']
        when 'break'
          caption(["Proceed?",":#{e1['label']}"])
          if judge(e1['cond'])
            result(-1)
            return self
          end
        when 'check'
          retr=(e1['retry']||1).to_i
          line=[retr > 1 ? "Waiting(#{retr})" : "Check",":#{e1['label']}"]
          caption(line)
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
  def caption(msgary)
    print "  "+Msg.color(msgary.shift,6)+msgary.join('')+" "
  end

  def result(code)
    str=" "
    case code
    when -1
      str << Msg.color("-> SKIP",3)
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
    @msg.clear
    retr.times{|n|
      sleep 1 if n > 0
      conds.all?{|h|
          ins=h['ins']
          key=h['ref']
          crt=@par.subst(h['val'])
          if val=getstat(ins,key)
            msg="#{ins}:#{key} / <#{val}> for [#{crt}]"
            if @msg.include?(msg)
              print "."
            else
              @msg << msg
            end
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
