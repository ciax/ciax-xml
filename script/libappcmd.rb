#!/usr/bin/ruby
require "libmsg"
require "libparam"

class AppCmd < Array
  include Math
  def initialize(adb)
    @v=Msg::Ver.new("app/cmd",9)
    @par=Param.new(adb,:select)
  end

  def setcmd(ssn)
    @v.msg{"Exec(ADB):#{ssn.first}"}
    @par.set(ssn)
    clear
    @par[:select].each{|e1|
      cmd=[]
      @v.msg(1){"GetCmd(FDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            cmd << e2
          when Hash
            str=@par.subst(e2['val'])
            str = e2['format'] % eval(str) if e2['format']
            @v.msg{"Calculated [#{str}]"}
            cmd << str
          end
        }
        push cmd
      ensure
        @v.msg(-1){"Exec(FDB):#{cmd}"}
      end
    }
    self
  end
end

if __FILE__ == $0
  require "libappdb"
  app,*cmd=ARGV
  begin
    adb=AppDb.new(app,cmd.empty?)
    ac=AppCmd.new(adb[:command])
    ac.setcmd(cmd).each{|cmd| p cmd}
  rescue SelectCMD
    Msg.exit(2)
  rescue UserError
    warn "Usage: #{$0} [app] [cmd] (par)"
    Msg.exit
  end
end
