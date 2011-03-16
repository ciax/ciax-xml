#!/usr/bin/ruby
require "libfrmmod"
require "libparam"
require "librepeat"
# Cmd Methods
class FrmCmd
  include FrmMod

  def initialize(doc,stat)
    @doc,@stat=doc,stat
    @v=Verbose.new("fdb/#{@doc['id']}/cmd".upcase)
    @cache={}
    @pass=true
    @par=Param.new
    @rep=Repeat.new
  end

  def setcmd(stm) # return = response select
    @sel=@doc.select_id('cmdframe',stm.first,'select')
    @par.setpar(@sel,stm)
    stm << '*' if /true|1/ === @sel['nocache']
    @cid=stm.join(':')
    @v.msg{'Select:'+@sel['label']+"(#{@cid})"}
    self
  end

  def getframe
    return unless @sel
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      @doc.find_each('cmdframe','ccrange'){|e|
        begin
          @v.msg(1){"Entering Ceck Code Range"}
          @ccary=getstr(e)
          @stat['cc']=checkcode(e,@ccary.join(''))
        ensure
          @v.msg(-1){"Exitting Ceck Code Range"}
        end
      }
      cmd=getstr(@doc['cmdframe']).join('')
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def getstr(e0)
    fary=[]
    @rep.each(e0){ |e1|
      case e1.name
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          fary+=getstr(@sel)
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when 'ccrange'
        fary+=@ccary
      when 'data'
        fary << get_data(e1)
      end
    }
    fary
  end

  def get_data(e)
    frame=''
    str=e.text
    [@rep,@par,@stat].each{|s|
      str=s.subst(str)
    } unless e['type'] == 'raw'
    case e['type']
    when 'formula'
      str=eval(str).to_s
      frame << encode(e,str)
      @v.msg{"GetFrame:(calculated)[#{str}]"}
    when 'csv'
      str.split(',').each{|s|
        frame << encode(e,s)
        @v.msg{"GetFrame:(csv)[#{s}]"}
      }
    else
      @v.msg{"GetFrame:#{e['label']}[#{str}]"}
      frame << encode(e,str)
    end
    frame
  end
end
