#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "liburiview"

class McrCmd
  include Math
  def initialize(mdb,view)
    @v=Msg::Ver.new("mcr",9)
    @par=Param.new(mdb)
    @view=Msg.type?(view,UriView)
  end

  def setcmd(ssn)
    @par.set(ssn)
  end

  def getcmd
    id=@par[:command]
    @v.msg{"Exec(MDB):#{id}"}
    @par[:select].each{|e1|
      case e1
      when Hash
        flg=e1[:cond].all?{|h|
          key=h['ref']
          cri=@par.subst(h['val'])
          val=@view['stat'][key]
          @v.msg{"Condition:[#{key}] of [#{cri}] vs <#{val}>"}
          cri == val
        }
        case e1[:type]
        when 'break'
          if flg
            Msg.warn("Skip:[#{id}]")
            return
          else
            Msg.warn("Proceed:[#{id}]")
          end
        when 'check'
          Msg.err("Interlock:[#{id}]") unless flg
        end
      else
        warn @par.subst(e1)
      end
    }
    self
  ensure
    @v.msg(-1){"Exec(ADB):#{id}"}
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
