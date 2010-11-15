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
    @sel=@ddb.select_id('cmdselect',stm.first)
    @par.setpar(@sel,stm)
    a=@sel.attributes
    stm << '*' if /true|1/ === a['nocache']
    @cid=stm.join(':')
    @v.msg{'Select:'+a['label']+"(#{@cid})"}
    self
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
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def getstr(e0)
    frame=''
    e0.each_element { |e1|
      a=e1.attributes
      case e1.name
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
        frame << @rep.repeat(e1){
          str=''
          e1.each_element{|e2|
            str << get_data(e2)
          }
          @v.msg{"GetFrame:(repeat)[#{str}]"}
          str
        }.join(a['delimiter'])
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
      [@rep,@par,@stat].each{|s|
        str=s.subst(str)
      }
      str=eval(str).to_s
      frame << encode(e,str)
      @v.msg{"GetFrame:(calculated)[#{str}]"}
    when 'csv'
      [@par,@stat].each{|s|
        str=s.subst(str)
      }
      str.split(',').each{|s|
        frame << encode(e,s)
        @v.msg{"GetFrame:(csv)[#{s}]"}
      }
    end
    frame
  end
end
