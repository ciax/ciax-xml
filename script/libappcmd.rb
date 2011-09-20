#!/usr/bin/ruby
require "libmsg"
require "libparam"

class AppCmd < Array
  include Math
  def initialize(adb)
    @v=Msg::Ver.new("#{adb['id']}/cmd",2)
    @par=Param.new(adb,:structure)
  end

  def setcmd(ssn)
    @v.msg{"Exec(ADB):#{ssn.first}"}
    @par.set(ssn)
    clear
    @par[:structure].each{|e1|
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
    adb=AppDb.new(app,true)
    ac=AppCmd.new(adb[:command])
    ac.setcmd(cmd).each{|cmd| p cmd}
  rescue UserError
    abort "Usage: appcmd [app] [cmd] (par)\n#{$!}"
  end
end
