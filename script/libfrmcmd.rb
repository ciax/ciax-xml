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
    @fdb={}
    init_main(doc,'cmdframe',@fdb)
    init_cc(doc,'cmdframe',@fdb)
    @flist=init_sel(doc,'cmdframe','command')
    @label=mk_db(@flist,'label')
    @par=Param.new(@label)
  end

  def setcmd(stm) # return = response select
    id=stm.first
    sel=@flist[id] || @par.list_cmd
    @fdb['select']=sel[:frame]
    @par.setpar(stm)
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === sel['nocache']
    @v.msg{'Select:'+@label[id]+"(#{@cid})"}
    self
  end

  def getframe
    return unless @fdb['select']
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      mk_frame('select')
      if ccm=@fdb[:method]
        @stat['cc']=checkcode(ccm,mk_frame('ccrange'))
      end
      cmd=mk_frame('main')
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def mk_frame(fname)
    @fstr[fname]=@fdb[fname].map{|a|
      case a
      when Hash
        @stat.subst(@par.subst(a)).split(',').map{|s|
          encode(a,s)
        }
      else
        @fstr[a]
      end
    }.join('')
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
