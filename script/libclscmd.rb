#!/usr/bin/ruby
require "libparam"
require "libverbose"
require "libclsdb"

class ClsCmd

  def initialize(cdbc,cls)
    @v=Verbose.new("#{cls}/stm",2)
    @par=Param.new(cdbc)
  end

  def setcmd(ssn)
    @id=ssn.first
    @par.setpar(ssn)
    self
  end

  def statements
    @v.msg{"Exec(CDB):#{@id}"}
    stma=[]
    @par[:statements].each{|e1|
      stm=[]
      @v.msg(1){"GetCmd(DDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            stm << e2
          when Hash
            str=@par.subst(e2['val'],e2['valid'])
            str = e2['format'] % eval(str) if e2['format']
            @v.msg{"Calculated [#{str}]"}
            stm << str
          end
        }
        stma << stm
      ensure
        @v.msg(-1){"Exec(DDB):#{stm}"}
      end
    }
    stma
  end
end
