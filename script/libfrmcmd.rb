#!/usr/bin/ruby
require "libframe"
require "libparam"
# Cmd Methods
class FrmCmd
  def initialize(fdb,field)
    @field=field
    @v=Msg::Ver.new("#{fdb['id']}/cmd".upcase,3)
    @cache={}
    @fstr={}
    @fdbc=fdb[:frame][:command]
    @sel=Hash[@fdbc]
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
    @par=Param.new(fdb[:command])
  end

  def getframe(cmd) # return = response select
    id=cmd.first
    @par.set(cmd)
    return unless @sel[:select]=@fdbc[:select][id]
    @v.msg{"Attr of Param:#{@par}"}
    cid=cmd.join(':')
    cid << ':*' if /true|1/ === @par[:nocache]
    @v.msg{"Select:#{@par[:label]}(#{cid})"}
    if frame=@cache[cid]
      @v.msg{"Cmd cache found [#{cid}]"}
    else
      mk_frame(:select)
      if @sel.key?(:ccrange)
        @frame.mark
        mk_frame(:ccrange)
        @field['cc']=@frame.checkcode
      end
      frame=mk_frame(:main)
      @cache[cid]=frame unless /\*/ === cid
    end
    frame
  end

  private
  def mk_frame(domain)
    @frame.set
    @sel[domain].each{|a|
      case a
      when Hash
        @field.subst(@par.subst(a['val'])).split(',').each{|s|
          @frame.add(s,a)
        }
      else # ccrange,select,..
        @frame.add(@fstr[a.to_sym])
      end
    }
    @fstr[domain]=@frame.copy
  end
end
