#!/usr/bin/ruby
require "libframe"
require "libfrmmod"
require "libparam"

# Rsp Methods
class FrmRsp
  include FrmMod

  def initialize(fdb,stat)
    @stat=stat
    @v=Verbose.new("#{fdb['id']}/rsp",3)
    @stat['frame']=fdb['id']
    @fdbs=fdb.fdbs
    @fdbsel=fdb.sels
    @par=Param.new(fdb.selc)
  end

  def setrsp(stm)
    cid=stm.first
    csel=@par.setpar(stm)
    rid=csel['response']
    sel=@fdbsel[rid] || @v.err("No such id [#{rid}]")
    @fdbs['select']=sel[:frame]
    @v.msg{"Set Statement #{stm}"}
    self
  end

  def getfield(time=Time.now)
    return "Send Only" unless @fdbs['select']
    frame=yield || @v.err("No String")
    tm=@fdbs['terminator']
    dm=@fdbs['delimiter']
    @frame=Frame.new(frame,dm,tm)
    getfield_rec(@fdbs['main'])
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
          @frame.mark
          getfield_rec(@fdbs['ccrange'])
          @cc = checkcode(@fdbs[:method],@frame.copy)
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(@fdbs['select'])
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
      data=@frame.cut(e0)
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
      idxs=[]
      e0[:index].each{|e1| # Index
        idxs << @par.subst(e1['range'])
      }
      @v.msg(1){"Array:#{e0['label']}[#{key}]:Range#{idxs}"}
      @stat[key]=mk_array(idxs,@stat[key]){
        @frame.cut(e0)
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
end
