#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "liburiview"

class McrCmd
  include Math
  def initialize(mdb,view)
    @v=Msg::Ver.new("mcr",9)
    @mdb=mdb
    @par=Param.new(mdb)
    @view=Msg.type?(view,UriView)
  end

  def setcmd(ssn)
    @par.set(ssn)
  end

  def getcmd
    id=@par[:command]
    Msg.msg("Exec(MDB):#{id}")
    @par[:select].each{|e1|
      case e1
      when Hash
        case e1['type']
        when 'break'
          Msg.warn("  Check Skip:[#{e1['label']}#{id}]")
          if judge(e1['cond'])
            Msg.warn("  Skip:[#{id}]")
            return
          else
            Msg.warn("  Proceed:[#{id}]")
          end
        when 'check'
          retr=(e1['retry']||1).to_i
          Msg.warn("  Check Interlock:[#{e1['label']}#{id}] (#{retr})")
          retr.times{
            break if judge(e1['cond'])
            sleep 1
          } && Msg.err("Interlock:[#{id}]")
        end
      else
        Msg.warn("  EXEC:#{@par.subst(e1)}")
      end
    }
    self
  end

  private
  def judge(conds)
    @view.upd
    conds.all?{|h|
      key=h['ref']
      cri=@par.subst(h['val'])
      val=@view['msg'][key]||@view['stat'][key]
      Msg.msg("   #{h['label']}(#{key}):<#{val}> for [#{cri}]")
      if /[a-zA-Z]/ === cri
        /#{cri}/ === val
      else
        cri == val
      end
    }
  end
end

if __FILE__ == $0
  require "libmcrdb"
  require "liburiview"
  mcr,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(mcr,cmd.empty?)
    view=UriView.new(mcr)
    ac=McrCmd.new(mdb,view)
    ac.setcmd(cmd)
    ac.getcmd
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  end
end
