#!/usr/bin/ruby
require "libparam"
require "libverbose"

class ClsCmd

  def initialize(cdb)
    @v=Verbose.new("#{cdb['id']}/cmd",2)
    @cdb=cdb.command
    @par=Param.new(@cdb)
  end

  def setcmd(ssn)
    @id=ssn.first
    @par.setpar(ssn).check_id
    self
  end

  def cmdset
    @v.msg{"Exec(CDB):#{@id}"}
    cmdset=[]
    @cdb[:select][@id].each{|e1|
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
