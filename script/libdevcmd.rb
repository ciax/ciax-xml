#!/usr/bin/ruby
require "libdevmod"
require "libparam"
require "librepeat"
# Cmd Methods
class DevCmd
  include DevMod

  def initialize(fdb,stat)
    @fdb,@stat=fdb,stat
    @v=Verbose.new("fdb/#{@fdb['id']}/cmd".upcase)
    @cache={}
    @pass=true
    @par=Param.new
    @rep=Repeat.new
  end

  def setcmd(stm) # return = response select
    @sel=@fdb.find_id('cmdframe','select',stm.first)
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
      cmd=getstr(@fdb['cmdframe']).join('')
      if @pass == 1
        @v.msg{"Retry by CC fail"}
        cmd=getstr(@fdb['cmdframe']).join('')
      end
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
        begin
          @v.msg(1){"Entering Ceck Code Range"}
          ccrange=getstr(e1)
          @stat['cc']=checkcode(e1,ccrange.join(''))
          fary+=ccrange
        ensure
          @v.msg(-1){"Exitting Ceck Code Range"}
        end
      when 'data'
        begin
          fary << get_data(e1)
        rescue RuntimeError
          if /cc/ === $!.to_s
            @v.msg{"Fail to Get CC"}
            @pass=!@pass
          end
          raise $! if @pass
        end
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
