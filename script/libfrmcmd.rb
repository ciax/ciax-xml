#!/usr/bin/ruby
require "libparam"
# Cmd Methods
class FrmCmd
  def initialize(fdb,stat)
    @fdb=fdb
    @stat=stat
    @v=Verbose.new("#{fdb['id']}/cmd".upcase,3)
    @cache={}
    @fstr={}
    @fdbc=fdb.command[:fdb]
    @selc=fdb.command[:sel]
    @par=Param.new
  end

  def setcmd(stm) # return = response select
    id=stm.first
    @v.list(@selc,"=== Command List ===") unless @selc.key?(id)
    @par.setpar(stm)
    @fdbc['select']=@selc[id][:frame]
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === @selc[id]['nocache']
    @v.msg{"Select:#{@par['label']}(#{@cid})"}
    self
  end

  def getframe
    return unless @fdbc['select']
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      mk_frame('select')
      if @fdbc.key?('ccrange')
        @stat['cc']=@fdb.checkcode(mk_frame('ccrange'))
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
