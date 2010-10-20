#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libmodxml"
require "libverbose"

class ClsCmd
  include ModXml

  def initialize(cdb)
    @cdb=cdb
    @v=Verbose.new("cdb/#{cdb['id']}/cmd".upcase)
    @rep=Repeat.new
    @par=Param.new
  end

  public
  def session(stm)
    par=stm.dup
    @par.setpar(stm)
    ecmd=@cdb.select_id('commands',par.shift)
    @v.msg{"CMD:Exec(CDB):#{ecmd.attributes['label']}"}
    ecmd.each_element {|e0|
      case e0.name
      when 'parameters'
        pary=par.dup
        e0.each_element{|e1| #//par
          validate(e1,pary.shift)
        }
      when 'statement'
        yield(get_cmd(e0))
      when 'repeat'
        repeat_cmd(e0){|e1| yield e1 }
      end
    }
  end

  private
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
    @v.msg(1){"CMD:GetCmd(DDB)"}
    begin
      e0.each_element{|e1| # //text or formula
        case e1.name
        when 'text'
          str=e1.text
          @v.msg{"CMD:GetText [#{str}]"}
        when 'formula'
          str=@rep.sub_index(e1.text)
          str=@par.sub_par(str)
          str=format(e1,eval(str))
          @v.msg{"CMD:Calculated [#{str}]"}
        end
        stm << str
      }
      stm
    ensure
      @v.msg(-1){"CMD:Exec(DDB):#{stm}"}
    end
  end
end
