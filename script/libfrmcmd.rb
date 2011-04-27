#!/usr/bin/ruby
require "libfrmmod"
require "libparam"
require "librepeat"
# Cmd Methods
class FrmCmd
  include FrmMod

  def initialize(doc,stat)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat=doc,stat
    @v=Verbose.new("fdb/#{@doc['id']}/cmd".upcase)
    @cache={}
    @label={}
    @response={}
    @rep=Repeat.new
    @frmstr={}
    @frmhash={}
    @frmsel={}
    @opt={}
    init_main
    init_cc
    init_sel
    @par=Param.new(@label)
  end

  def setcmd(stm) # return = response select
    @id=stm.first
    @frmhash['select']=@frmsel[@id] || @par.list_cmd
    @par.setpar(stm)
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === @opt[@id]['nocache']
    @v.msg{'Select:'+@label[@id]+"(#{@cid})"}
    self
  end

  def getframe
    return unless @id
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      mk_frame('select')
      @stat['cc']=checkcode(@ccm,mk_frame('ccrange')) if @ccm
      cmd=mk_frame('main')
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def mk_frame(fname)
    @frmstr[fname]=@frmhash[fname].map{|a|
      case a
      when Hash
        @stat.subst(@par.subst(a)).split(',').map{|s|
          encode(a,s)
        }
      else
        @frmstr[a]
      end
    }.join('')
  end

  #Initialize
  def init_main
    frame=[]
    begin
      @v.msg(1){"Start Main Frame"}
      @doc['cmdframe'].each{|e1|
        frame << init_data(e1)
      }
    ensure
      @v.msg(-1){"End Main Frame"}
    end
    @v.msg{"InitMainFrame:[#{frame}]"}
    @frmhash['main']=frame.freeze
  end

  def init_cc
    @doc.find_each('cmdframe','ccrange'){|e0|
      begin
        @v.msg(1){"Start Ceck Code Frame"}
        frame=[]
        e0.each{|e1|
          frame << init_data(e1)
        }
        @ccm=e0['method']
        @v.msg{"InitCCFrame:[#{frame}]"}
        @frmhash['ccrange']=frame.freeze
      ensure
        @v.msg(-1){"End Ceck Code Frame"}
      end
    }
  end

  def init_sel
    seldb={}
    @doc.find_each('cmdframe','command'){|e0|
      begin
        @v.msg(1){"Start Select Frame"}
        frame=[]
        @rep.each(e0){|e1|
          frame << init_data(e1)
        }
        selh=e0.to_h
        id=selh.delete('id')
        @label[id]=selh.delete('label')
        @response[id]=selh.delete('response')
        @opt[id]=selh.freeze
        @v.msg{"InitSelFrame:[#{frame}]"}
        @frmsel[id] = frame.freeze
      ensure
        @v.msg(-1){"End Select Frame"}
      end
    }
    seldb
  end

  def init_data(e)
    case e.name
    when 'data'
      attr=e.to_h
      label=attr.delete('label')
      attr['val']=@rep.subst(e.text)
      @v.msg{"Data:#{label}[#{e}]"}
      attr
    else
      e.name
    end
  end
end
