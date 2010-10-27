#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libmodxml"
require "libverbose"

class ClsCmd
  include ModXml
  attr_reader :par

  def initialize(cdb)
    @cdb=cdb
    @v=Verbose.new("cdb/#{cdb['id']}/cmd".upcase)
    @rep=Repeat.new
    @par=Param.new
  end

  public
  def session(stm)
    @par.setpar(stm)
    ecmd=@cdb.select_id('commands',stm.first)
    @v.msg{"Exec(CDB):#{ecmd.attributes['label']}"}
    ecmd.each_element {|e0|
      case e0.name
      when 'parameters'
        i=0
        e0.each_element{|e1| #//par
          validate(e1,@par[i+=1])
        }
      when 'statement'
        yield(get_cmd(e0))
      when 'repeat'
        repeat_cmd(e0){|e1| yield e1 }
      when 'async'
        return e0
      end
    }
    nil
  end

  #Cmd Method
  def repeat_cmd(e0)
    @rep.repeat(e0){ |e1|
      case e1.name
      when 'statement'
        yield(get_cmd(e1))
      when 'repeat'
        repeat_cmd(e1){|e2| yield e2}
      end
    }
  end

  def get_cmd(e0) # //stm
    stm=[]
    @v.msg(1){"GetCmd(DDB)"}
    begin
      e0.each_element{|e1| # //text or formula
        case e1.name
        when 'text'
          str=e1.text
          @v.msg{"GetText [#{str}]"}
        when 'formula'
          str=@rep.sub_index(e1.text)
          str=@par.sub_par(str)
          str=format(e1,eval(str))
          @v.msg{"Calculated [#{str}]"}
        end
        stm << str
      }
      stm
    ensure
      @v.msg(-1){"Exec(DDB):#{stm}"}
    end
  end
end
