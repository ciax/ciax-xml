#!/usr/bin/ruby
require "libmsg"
require "libparam"

class AppCmd < Array
  include Math
  def initialize(adb)
    @v=Msg::Ver.new("#{adb['id']}/cmd",2)
    @adb=adb[:structure]
    @par=Param.new(adb)
  end

  def setcmd(ssn)
    @id=ssn.first
    @par.set(ssn)
    @v.msg{"Exec(ADB):#{@id}"}
    clear
    @adb[@id].each{|e1|
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
