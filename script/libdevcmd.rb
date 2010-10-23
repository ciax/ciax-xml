#!/usr/bin/ruby
require "libmodxml"
require "libparam"
require "librepeat"
# Cmd Methods
class DevCmd
  include ModXml

  def initialize(ddb,stat)
    @ddb,@stat=ddb,stat
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
    @cache={}
    @par=Param.new
    @rep=Repeat.new
  end

  def setcmd(stm) # return = response select
    @cid=stm.join(':')
    @par.setpar(stm)
    @sel=@ddb.select_id('cmdselect',stm.first)
    @v.msg{'Select:'+@sel.attributes['label']}
  end

  def getframe
    return unless @sel
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      if ccn=@ddb['cmdccrange']
        begin
          @v.msg(1){"Entering Ceck Code Range"}
          @ccrange=getstr(ccn)
          @stat['cc']=checkcode(ccn,@ccrange)
        ensure
          @v.msg(-1){"Exitting Ceck Code Range"}
        end
      end
      cmd=getstr(@ddb['cmdframe'])
      @cache[@cid]=cmd unless @sel.attributes['nocache']
    end
    cmd
  end

  private
  def getstr(e0)
    frame=''
    e0.each_element { |e1|
      a=e1.attributes
      case e1.name
      when 'parameters'
        i=0
        e1.each_element{|e2|
          validate(e2,@par[i+=1])
        }
      when 'selected'
        begin
          @v.msg(1){"Entering Selected Node"}
          frame << getstr(@sel)
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'repeat'
        @rep.repeat(e1){|e2|
          frame << get_data(e2)
        }
      else
        frame << get_data(e1)
      end
    }
    frame
  end

  def get_data(e)
    frame=''
    a=e.attributes
    str=e.text
    case e.name
    when 'data'
      @v.msg{"GetFrame:#{a['label']}[#{str}]"}
      frame << encode(e,str)
    when 'formula'
      str=@rep.sub_index(str)
      str=@par.sub_par(str)
      str=eval(@stat.sub_stat(str)).to_s
      @v.msg{"GetFrame:(calculated)[#{str}]"}
      frame << encode(e,str)
    when 'csv'
      str=@par.sub_par(str)
      @par.sub_par(str).split(',').each{|s|
        @v.msg{"GetFrame:(csv)[#{s}]"}
        frame << encode(e,s)
      }
    end
    frame
  end
end
