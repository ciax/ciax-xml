#!/usr/bin/ruby
require "libframe"
require "libfrmmod"
require "libparam"

# Rsp Methods
class FrmRsp
  include FrmMod

  def initialize(doc,stat)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat,@sel=doc,stat
    @v=Verbose.new("#{@doc['id']}/rsp",3)
    @stat['frame']=@doc['id']
    @fdb={}
    init_main(@doc,'rspframe',@fdb)
    init_cc(@doc,'rspframe',@fdb)
    @rlist=init_sel(@doc,'rspframe','response')
    @clist=init_sel(@doc,'cmdframe','command')
    @par=Param.new(mk_db(@clist,'label'))
  end

  def setrsp(stm)
    cid=stm.first
    csel=@clist[cid] || @par.list_cmd
    rid=csel['response']
    sel=@rlist[rid] || @v.err("No such id [#{rid}]")
    @fdb['select']=sel[:frame]
    @par.setpar(stm)
    @v.msg{"Set Statement #{stm}"}
    self
  end

  def getfield(time=Time.now)
    return "Send Only" unless @fdb['select']
    frame=yield || @v.err("No String")
    tm=@fdb['terminator']
    dm=@fdb['delimiter']
    @frm=Frame.new(frame,dm,tm)
    getfield_rec(@fdb['main'])
    if cc=@stat.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch <#{cc}> != (#{@cc})")
      @v.msg{"Verify:CC OK <#{cc}>"}
    end
    @stat['time']="%.3f" % time.to_f
    Hash[@stat]
  end

  private
  # Process Frame to Field
  def getfield_rec(e0)
    e0.each{|e1|
      case e1
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          @frm.mark
          getfield_rec(@fdb['ccrange'])
          @cc = checkcode(@fdb[:method],@frm.copy)
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(@fdb['select'])
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when Hash
        if e1[:index]
          frame_to_array(e1)
        else
          frame_to_field(e1)
        end
      end
    }
  end

  def frame_to_field(e0)
    begin
      @v.msg(1){"Field:#{e0['label']}"}
      data=decode(e0,@frm.cut(e0))
      if key=e0['assign']
        @stat[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
      if val=e0['val']
        val=eval(val).to_s if e0['decode'] == 'chr'
        @v.msg{"Verify:[#{val}] and <#{data}>"}
        val == data || @v.err("Verify Mismatch <#{data}> != [#{val}]")
      end
    ensure
      @v.msg(-1){"Field:End"}
    end
  end

  def frame_to_array(e0)
    key=e0['assign'] || @v.err("No key for Array")
    begin
      @v.msg(1){"Array:#{e0['label']}[#{key}]"}
      idxs=[]
      e0[:index].each{|e1| # Index
        idxs << @par.subst(e1['range'])
      }
      @v.msg(1){"Array:Indexs#{e0[:index]} -> #{idxs}"}
      @stat[key]=mk_array(idxs,@stat[key]){
        decode(e0,@frm.cut(e0))
      }
    ensure
      @v.msg(-1){"Array:Assign[#{key}]"}
    end
  end

  def mk_array(idx,field)
    # make multidimensional array
    # i.e. idxary=[0,0:10,0] -> field[0][0][0] .. field[0][10][0]
    return yield if idx.empty?
    fld=field||[]
    f,l=idx[0].split(':').map{|i| eval(i)}
    Range.new(f,l||f).each{|i|
      @v.msg{"Array:Index[#{i}]"}
      fld[i] = mk_array(idx[1..-1],fld[i]){yield}
    }
    fld
  end

  def init_element(e)
    case e.name
    when 'field'
      attr=e.to_h
      attr['val']=e.text
      if id=attr['assign']
        @stat[id]=@stat[id] || attr['val']
      end
      @v.msg{"InitElement:#{attr['label']} #{attr}"}
      attr
    when 'array'
      attr=e.to_h
      id=attr['assign']
      idx=attr[:index]=[]
      e.each{|e1|
        idx << e1.to_h
      }
      @stat[id]=@stat[id] || init_array(idx.map{|h| h['size']}){''}
      attr
    when 'ccrange','select'
      e.name
    else
      nil
    end
  end
  
  def init_array(sary,field=nil)
    return yield if sary.empty?
    a=field||[]
    sary[0].times{|i|
      a[i]=init_array(sary[1..-1],a[i]){yield}
    }
    a
  end
end
