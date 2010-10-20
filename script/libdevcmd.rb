#!/usr/bin/ruby
require "libmodxml"
require "libparam"

# Cmd Methods
class DevCmd
  include ModXml

  def initialize(ddb,var)
    @ddb,@var=ddb,var
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
    @cache={}
    @par=Param.new
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
          @var.stat['cc']=checkcode(ccn,@ccrange)
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
  def getstr(e)
    frame=''
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'parameters'
        i=0
        c.each_element{|d|
          validate(d,@par[i+=1])
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
      when 'data'
        str=c.text
        @v.msg{"GetFrame:#{a['label']}[#{str}]"}
        frame << encode(c,str)
      when 'formula'
        str=@par.sub_par(c.text)
        str=eval(@var.sub_var(str)).to_s
        @v.msg{"GetFrame:(calculated)[#{str}]"}
        frame << encode(c,str)
      when 'csv'
        str=@par.sub_par(c.text)
        @par.sub_par(str).split(',').each{|str|
          @v.msg{"GetFrame:(csv)[#{str}]"}
          frame << encode(c,str)
        }
      end
    }
    frame
  end
end
