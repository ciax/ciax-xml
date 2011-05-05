#!/usr/bin/ruby
require "libfrmmod"
require "libparam"
require "librepeat"
# Cmd Methods
class FrmCmd
  include FrmMod

  def initialize(doc,stat)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @stat=stat
    @v=Verbose.new("#{doc['id']}/cmd".upcase,3)
    @cache={}
    @rep=Repeat.new
    @fstr={}
    @fdbc=init_main(doc,'cmdframe')
    @par=Param.new(init_sel(doc,'cmdframe','command'))
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

  #Initialize
  def init_element(e)
    case e.name
    when 'data'
      attr=e.to_h
      label=attr.delete('label')
      attr['val']=@rep.subst(e.text)
      @v.msg{"Data:#{label}[#{attr}]"}
      attr
    else
      e.name
    end
  end
end
