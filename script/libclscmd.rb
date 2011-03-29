#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libverbose"

class ClsCmd
  attr_reader :par

  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc=doc
    @v=Verbose.new("doc/#{doc['id']}/cmd".upcase)
    @rep=Repeat.new
    @par=Param.new
  end

  def setcmd(ssn)
    @sel=@doc.select_id('commands',ssn.first)
    @par.setpar(@sel,ssn)
    self
  end

  def session
    @v.msg{"Exec(CDB):#{@sel['label']}"}
    get_cmd(@sel)
  end

  private
  #Cmd Method
  def get_cmd(e0) # //session
    stma=[]
    @rep.each(e0){|e1|
      next unless /statement/ === e1.name
      stm=[e1['command']]
      @v.msg(1){"GetCmd(DDB):#{stm}"}
      begin
        e1.each{|e2| # //argv
          str=e2.text
          [@rep,@par].each{|s|
            str=s.subst(str)
          }
          str=e2['format'] % eval(str) if e2['format']
          @v.msg{"Calculated [#{str}]"}
          stm << str
        }
        stma << stm
      ensure
        @v.msg(-1){"Exec(DDB):#{stm}"}
      end
    }
    stma
  end
end
