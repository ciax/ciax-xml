#!/usr/bin/ruby
require "libfrmmod"
require "libparam"
# Cmd Methods
class FrmCmd
  include FrmMod

  def initialize(fdb,stat)
    @stat=stat
    @v=Verbose.new("#{fdb['id']}/cmd".upcase,3)
    @cache={}
    @fstr={}
    @fdbc=fdb.fdbc
    @par=Param.new(fdb.selc)
  end

  def setcmd(stm) # return = response select
    id=stm.first
    @par.setpar(stm)
    @fdbc['select']=@par[:frame]
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === @par['nocache']
    @v.msg{"Select:#{@par['label']}(#{@cid})"}
    self
  end

  def getframe
    return unless @fdbc['select']
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      mk_frame('select')
      if ccm=@fdbc[:method]
        @stat['cc']=checkcode(ccm,mk_frame('ccrange'))
      end
      cmd=mk_frame('main')
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def mk_frame(fname)
    @fstr[fname]=@fdbc[fname].map{|a|
      case a
      when Hash
        @stat.subst(@par.subst(a['val'],a['valid'])).split(',').map{|s|
          encode(a,s)
        }
      else
        @fstr[a]
      end
    }.join('')
  end

  def encode(e,str) # Num -> Chr
    cdc=e['encode']
    if pck={'chr'=>'C','bew'=>'n','lew'=>'v'}[cdc]
      code=[eval(str)].pack(pck)
      @v.msg{"Encode:(#{cdc}) [#{str}] -> [#{code}]"}
      str=code
    end
    if fmt=e['format']
      @v.msg{"Formatted code(#{fmt}) [#{str}]"}
      code=fmt % eval(str)
      @v.msg{"Formatted code(#{fmt}) [#{str}] -> [#{code}]"}
      str=code
    end
    str.to_s
  end
end
