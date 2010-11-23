#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libmodxml"
require "libverbose"

class ClsCmd
  include ModXml
  attr_reader :par

  def initialize(cdb)
    @cdb=@sel=cdb
    @v=Verbose.new("cdb/#{cdb['id']}/cmd".upcase)
    @rep=Repeat.new
    @par=Param.new
  end

  def setcmd(stm)
    @sel=@cdb.select_id('commands',stm.first)
    @par.setpar(@sel,stm)
    self
  end

  def session
    @v.msg{"Exec(CDB):#{@sel['label']}"}
    get_cmd(@sel)
  end

  private
  #Cmd Method
  def get_cmd(e0) # //stm
    dstm=[]
    e0.each{|e1|
      case e1.name
      when 'statement'
        @v.msg(1){"GetCmd(DDB)"}
        argv=[]
        begin
          e1.each{|e2| # //argv
            str=e2['formula']
            [@rep,@par].each{|s|
              str=s.subst(str)
            }
            str=eval(str)
            @v.msg{"Calculated [#{str}]"}
            argv << str
          }
          dstm << e1['format'] % argv
        ensure
          @v.msg(-1){"Exec(DDB):#{argv}"}
        end
      when 'repeat'
        @rep.repeat(e1){ dstm+= get_cmd(e1)}
      end
    }
    dstm
  end
end
