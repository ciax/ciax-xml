#!/usr/bin/ruby
require "libstat"
require "libparam"
require "librepeat"
require "libmodxml"
require "libverbose"

class ClsCmd < Stat
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
    xpcmd=@cdb.select_id('commands',par.shift)
    @v.msg{"CMD:Exec(CDB):#{xpcmd.attributes['label']}"}
    xpcmd.each_element {|c|
      case c.name
      when 'parameters'
        pary=par.dup
        c.each_element{|d| #//par
          validate(d,pary.shift)
        }
      when 'statement'
        yield(get_cmd(c))
      when 'repeat'
        repeat_cmd(c){|d| yield d }
      end
    }
  end

  private
  #Cmd Method
  def repeat_cmd(e)
    @rep.repeat(e){ |f|
      case f.name
      when 'statement'
        yield(get_cmd(f))
      when 'repeat'
        repeat_cmd(f){ |g| yield g }
      end
    }
  end

  def get_cmd(e) # //stm
    stm=[]
    @v.msg(1){"CMD:GetCmd(DDB)"}
    begin
      e.each_element{|d| # //text or formula
        case d.name
        when 'text'
          str=d.text
          @v.msg{"CMD:GetText [#{str}]"}
        when 'formula'
          str=@rep.sub_index(d.text)
          str=@par.sub_par(str)
          str=format(d,eval(sub_var(str)))
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
