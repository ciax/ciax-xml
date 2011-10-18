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
    @view={}
  end

  def exe(cmd)
    @par.set(cmd)
    id=@par[:id]
    puts "Exec(MDB):#{id}"
    @par[:select].each{|e1|
      case e1
      when Hash
        case e1['type']
        when 'break'
          puts "  Skip?:[#{e1['label']}]"
          if judge(e1['cond'])
            puts "  Skip:[#{id}]"
            return
          else
            puts "  Proceed:[#{id}]"
          end
        when 'check'
          retr=(e1['retry']||1).to_i
          if retr > 1
            puts "  Waiting for:#{e1['label']} (#{retr})"
          else
            puts "  Check:#{e1['label']} (#{retr})"
          end
          if retr.times{|n|
              break if judge(e1['cond'],n)
              sleep 1
            }
            puts (retr > 1 ? "\nTimeout:[#{id}]" : "NG:[#{id}]")
            return self
          end
        end
      else
        puts "  EXEC:#{@par.subst(e1)}"
      end
    }
    self
  end

  private
  def judge(conds,n=0)
    m=0
    conds.all?{|h|
      ins=h['ins']
      key=h['ref']
      crt=@par.subst(h['val'])
      val=getstat(ins,key)
      if n==0
        puts "   #{key}:<#{val}> for [#{crt}]"
      elsif n==1 && m==0
        print "    Waiting"
      elsif m==0
        print  "."
      end
      m+=1
      if /[a-zA-Z]/ === crt
        /#{crt}/ === val
      else
        crt == val
      end
    }
  end

  def getstat(ins,id)
    @view[ins]||=Rview.new(ins)
    view=@view[ins].upd
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
