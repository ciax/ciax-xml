#!/usr/bin/ruby
require "libparam"
require "libmsg"

class AppCmd
  def initialize(adb)
    @v=Msg::Ver.new("#{adb['id']}/cmd",2)
    @adb=adb[:structure]
    @par=Param.new(adb)
  end

  def setcmd(ssn)
    @id=ssn.first
    @par.set(ssn)
    self
  end

  def cmdset
    @v.msg{"Exec(CDB):#{@id}"}
    cmdset=[]
    @adb[@id].each{|e1|
      cmd=[]
      @v.msg(1){"GetCmd(DDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            cmd << e2
          when Hash
            str=@par.subst(e2['val'],e2['valid'])
            str = e2['format'] % eval(str) if e2['format']
            @v.msg{"Calculated [#{str}]"}
            cmd << str
          end
        }
        cmdset << cmd
      ensure
        @v.msg(-1){"Exec(DDB):#{cmd}"}
      end
    }
    cmdset
  end
end
