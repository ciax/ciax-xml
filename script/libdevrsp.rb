#!/usr/bin/ruby
require "libdevmod"
require "libparam"
# Rsp Methods
class DevRsp
  include DevMod

  def initialize(fdb,stat)
    @fdb,@stat,@sel=fdb,stat
    @v=Verbose.new("fdb/#{@fdb['id']}/rsp".upcase)
    @frame=''
    @fary=[]
    @fp=0
    @par=Param.new
    init_field
  end

  def setrsp(stm)
    cmd=@fdb.find_id('cmdframe','select',stm.first)
    @par.setpar(cmd,stm)
    @sel=cmd['response']
    self
  end

  def getfield(time=Time.now)
    return "Send Only" unless @sel
    frame=yield || @v.err("No String")
    @v.msg{"ResponseFrame:[#{frame}]" }
    if tm=@fdb['rspframe']['terminator']
      frame.chomp!(eval('"'+tm+'"'))
      @v.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
    end
    if dm=@fdb['rspframe']['delimiter']
      @fary=frame.split(eval('"'+dm+'"'))
      @v.msg{"Split:[#{frame}] by [#{dm}]" }
    else
      @fary=[frame]
    end
    getfield_rec(@fdb['rspframe'])
    if cc=@stat.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch <#{cc}> != (#{@cc})")
      @v.msg{"Verify:CC OK <#{cc}>"}
    end
    @stat['time']="%.3f" % time.to_f
    Hash[@stat]
  end

  private
  # Fill default values in the Field
  def init_field
    @v.msg(1){"Field:Initialize"}
    begin
      init_rec(@fdb['rspframe'])
      @stat['device']=@fdb['id']
    ensure
      @v.msg(-1){"Field:Initialized"}
    end
  end

  def init_rec(e0)
    fill=''
    e0.each{|e1| #field|array|vefiry
      case e1.name
      when 'ccrange'
        init_rec(e1)
      when 'select'
        e1.each{|e2|
          init_rec(e2)
        }
      when 'field'
        if assign=e1['assign']
          @v.msg{"Field:Init Field[#{assign}]"}
          @stat[assign]=fill unless @stat[assign]
        end
      when 'array'
        assign=e1['assign']
        @v.msg{"Field:Init Array[#{assign}]"}
        sary=[]
        e1.each{|e2|
          sary << e2['size'].to_i
        }
        @stat[assign]=init_array(sary){fill} unless @stat[assign]
      end
    }
  end

  def init_array(sary,field=nil)
    return yield if sary.empty?
    a=field||[]
    sary[0].times{|i|
      a[i]=init_array(sary[1..-1],a[i]){yield}
    }
    a
  end

  # Process Frame to Field
  def getfield_rec(e0)
    e0.each{|e1|
      case e1.name
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          fst=@fp;getfield_rec(e1)
          @cc = checkcode(e1,@frame.slice(fst...@fp))
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(e1.select('id',@sel))
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when 'field'
        frame_to_field(e1)
      when 'array'
        field_array(e1)
      end
    }
  end

  def frame_to_field(e0)
    @v.msg(1){"Field:#{e0['label']}"}
    begin
      data=decode(e0,cut_frame(e0))
      if key=e0['assign']
        @stat[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
      if val=e0.text
        val=eval(val).to_s if e0['decode'] == 'chr'
        @v.msg{"Verify:[#{val}] and <#{data}>"}
        val == data || @v.err("Verify Mismatch <#{data}> != [#{val}]")
      end
    ensure
      @v.msg(-1){"Field:End"}
    end
  end

  def field_array(e0)
    idxs=[]
    @v.msg(1){"Array:#{e0['label']}"}
    begin
      key=e0['assign'] || @v.err("No key for Array")
      e0.each{|e1| # Index
        idxs << @par.subst(e1['range'])
      }
      @stat[key]=mk_array(idxs,@stat[key]){
        decode(e0,cut_frame(e0))
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

  def cut_frame(e0)
    if @fp >= @frame.size
#      @v.err("No more string in frame") if @fary.empty?
      @frame=@fary.shift||''
      @fp=0
    end
    len=e0['length']||@frame.size
    str=@frame.slice(@fp,len.to_i)
    @fp+=len.to_i
    @v.msg{"CutFrame: <#{str}> by size=[#{len}]"}
    if r=e0['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame: <#{str}> by range=[#{r}]"}
    end
    str
  end
end
