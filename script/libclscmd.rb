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
    @rep.each(e0){|e1|
      next unless /statement/ === e1.name
      @v.msg(1){"GetCmd(DDB)"}
      argv=[]
      begin
        e1.each{|e2| # //argv
          str=e2.text
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
    }
    dstm
  end
end
