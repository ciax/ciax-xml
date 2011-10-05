#!/usr/bin/ruby
require "libmsg"
require "libparam"

class McrObj
  attr_reader :line
  def initialize(mdb,cli)
    @v=Msg::Ver.new("mcr",9)
    @mdb=mdb
    @par=Param.new(mdb)
    @cli=Msg.type?(cli,Client)
    @line=[]
  end

  def setcmd(ssn)
    @par.set(ssn)
  end

  def getcmd
    id=@par[:command]
    @line << "Exec(MDB):#{id}"
    @par[:select].each{|e1|
      case e1
      when Hash
        case e1['type']
        when 'break'
          @line << "  Check Skip:[#{e1['label']}#{id}]"
          if judge(e1['cond'])
            @line << "  Skip:[#{id}]"
            return
          else
            @line << "  Proceed:[#{id}]"
          end
        when 'check'
          retr=(e1['retry']||1).to_i
          @line << "  Check Interlock:[#{e1['label']}#{id}] (#{retr})"
          if retr.times{|n|
              break if judge(e1['cond'],n)
              sleep 1
            }
          then
            @line << (retr > 1 ? "Timeout:[#{id}]" : "Interlock:[#{id}]")
            return self
          end
        end
      else
        @line << "  EXEC:#{@par.subst(e1)}"
      end
    }
    self
  end

  private
  def judge(conds,n=0)
    @cli.view.upd
    conds.all?{|h|
      key=h['ref']
      cri=@par.subst(h['val'])
      val=@cli.view['msg'][key]||@cli.view['stat'][key]
      if n==0
        @line << "   #{h['label']}(#{key}):<#{val}> for [#{cri}]"
      else
        @line.last << "."
      end
      if /[a-zA-Z]/ === cri
        /#{cri}/ === val
      else
        cri == val
      end
    }
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libmcrdb"
  require "libclient"
  mcr,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(mcr,cmd.empty?)
    idb=InsDb.new(mcr).cover_app
    cli=Client.new(idb)
    ac=McrObj.new(mdb,cli)
    ac.setcmd(cmd)
    ac.getcmd
    puts ac.line
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
end
