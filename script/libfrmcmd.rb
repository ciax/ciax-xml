#!/usr/bin/ruby
require "libframe"
require "libparam"
# Cmd Methods
class FrmCmd
  def initialize(fdb,field)
    @fdb=fdb
    @field=field
    @v=Verbose.new("#{fdb['id']}/cmd".upcase,3)
    @cache={}
    @fstr={}
    @fdbc=fdb.frame[:command]
    @frame=Frame.new(fdb['endian'])
    @par=Param.new(@fdb.command)
  end

  def setcmd(stm) # return = response select
    id=stm.first
    @par.setpar(stm).check_id
    @fdbc[:select]=@par[:select]
    @v.msg{"Attr of Param:#{@par}"}
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === @par[:nocache]
    @v.msg{"Select:#{@par[:label]}(#{@cid})"}
    self
  end

  def getframe
    return unless @fdbc[:select]
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      mk_frame(:select)
      if @fdbc.key?(:ccrange)
        @field['cc']=@fdb.checkcode(mk_frame(:ccrange))
      end
      cmd=mk_frame(:main)
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def mk_frame(fname)
    @frame.set
    @fdbc[fname].each{|a|
      case a
      when Hash
        @field.subst(@par.subst(a['val'],a['valid'])).split(',').each{|s|
          @frame.add(s,a)
        }
      else # ccrange,select,..
        @frame.add(@fstr[a.to_sym])
      end
    }
    @fstr[fname]=@frame.copy
  end
end
