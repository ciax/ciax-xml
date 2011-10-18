#!/usr/bin/ruby
require "libmsg"
require "libparam"

class McrObj
  attr_reader :line
  def initialize(mdb,cli)
    @v=Msg::Ver.new("mcr",9)
    @mdb=mdb
    @par=Param.new(mdb)
    @cli=Msg.type?(cli,AppCl)
    @view=@cli.view
    @line=[]
  end

  def exe(cmd)
    @par.set(cmd)
    id=@par[:id]
    p Thread.new{
      Thread.pass
      @line.clear << "Exec(MDB):#{id}"
      @par[:select].each{|e1|
        case e1
        when Hash
          case e1['type']
          when 'break'
            @line << "  Check Skip:[#{e1['label']}]"
            if judge(e1['cond'])
              @line << "  Skip:[#{id}]"
              return
            else
              @line << "  Proceed:[#{id}]"
            end
          when 'check'
            retr=(e1['retry']||1).to_i
            @line << "  Check Interlock:[#{e1['label']}] (#{retr})"
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
    }
    self
  end

  def to_s
    @line.join("\n")
  end


  private
  def judge(conds,n=0)
    @view.upd
    conds.all?{|h|
      key=h['ref']
      cri=@par.subst(h['val'])
      val=@view['msg'][key]||@view['stat'][key]
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
  require "libappcl"
  require "libshell"
  id,*cmd=ARGV
  ARGV.clear
  begin
    mdb=McrDb.new(id,cmd.empty?)
    adb=InsDb.new(id).cover_app
    cli=AppCl.new(adb)
    ac=McrObj.new(mdb,cli)
  rescue SelectCMD
    Msg.exit(2)
  rescue SelectID
    warn "Usage: #{$0} [mcr] [cmd] (par)"
    Msg.exit
  rescue UserError
    Msg.exit(3)
  end
  Shell.new("mcr>"){|cmd|
    ac.exe(cmd) unless cmd.empty?
    ac.to_s
  }
end
