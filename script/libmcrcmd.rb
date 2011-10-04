#!/usr/bin/ruby
require "libmsg"
require "libparam"
require 'json'

class McrCmd
  include Math
  def initialize(mdb)
    @v=Msg::Ver.new("mcr",9)
    @par=Param.new(mdb)
  end

  def setcmd(ssn)
    @par.set(ssn)
  end

  def getcmd(stat)
    Msg.type?(stat,Hash)
    id=@par[:command]
    @v.msg{"Exec(MDB):#{id}"}
    @par[:select].each{|e1|
      case e1
      when Hash
        flg=e1[:cond].all?{|h|
          key=h['ref']
          cri=@par.subst(h['val'])
          val=stat[key]
          @v.msg{"Condition:[#{key}] of [#{cri}] vs <#{val}>"}
          cri == val
        }
        case e1[:type]
        when 'break'
          if flg
            @v.msg{"Skip:[#{id}]"}
            return
          else
            @v.msg{"Proceed:[#{id}]"}
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
  mcr,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(mcr,cmd.empty?)
    ac=McrCmd.new(mdb)
    ac.setcmd(cmd)
    ac.getcmd(JSON.load(gets(nil))['stat'])
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [mcr] [cmd] (par) < view_file"
    Msg.exit
  end
end
