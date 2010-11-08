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
    @par.setpar(stm)
    @sel=@cdb.select_id('commands',stm.first)
    self
  end

  def session
    a=@sel.attributes
    @v.msg{"Exec(CDB):#{a['label']}"}
    dstm=[]
    @sel.each_element {|e1|
      case e1.name
      when 'parameters'
        i=0
        e1.each_element{|e2| #//par
          validate(e2,@par[i+=1])
        }
      when 'statement'
        dstm << get_cmd(e1)
      when 'repeat'
        dstm += repeat_cmd(e1){|e2| yield e2 }
      end
    }
    dstm
  end

  private
  #Cmd Method
  def repeat_cmd(e0)
    dstm=[]
    @rep.repeat(e0){
      e0.each_element{|e1|
        case e1.name
        when 'statement'
          dstm << get_cmd(e1)
        when 'repeat'
          dstm+= repeat_cmd(e1){|e2| yield e2}
        end
      }
    }
    dstm
  end

  def get_cmd(e0) # //stm
    dstm=[]
    @v.msg(1){"GetCmd(DDB)"}
    begin
      e0.each_element{|e1| # //text or formula
        str=e1.text
       case e1.name
        when 'text'
          @v.msg{"GetText [#{str}]"}
        when 'formula'
          [@rep,@par].each{|s|
            str=s.subst(str)
          }
          str=format(e1,eval(str))
          @v.msg{"Calculated [#{str}]"}
        end
        dstm << str
      }
      dstm
    ensure
      @v.msg(-1){"Exec(DDB):#{dstm}"}
    end
  end
end
