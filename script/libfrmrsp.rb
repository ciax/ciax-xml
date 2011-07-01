#!/usr/bin/ruby
require "libframe"
require "libparam"

# Rsp Methods
class FrmRsp
  def initialize(fdb,field)
    @fdb=fdb
    @field=field
    @v=Verbose.new("#{fdb['id']}/rsp",3)
    @field['frame']=fdb['id']
    @fdbs=fdb.frame[:status]
    @par=Param.new(fdb.command)
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
  end

  # Block accepts [time,frame]
  def setrsp(cmd)
    if rid=@par.setpar(cmd).check_id[:response]
      sel=@fdb.status[:select][rid] || @v.err("No such response id [#{rid}]")
      @fdbs[:select]=sel
      @v.msg{"Set Statement #{cmd}"}
      time,frame=yield
      @v.err("No Response") unless frame
      @field['time']="%.3f" % time.to_f
      if tm=@fdbs['terminator']
        frame.chomp!(eval('"'+tm+'"'))
        @v.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
      end
      if dm=@fdbs['delimiter']
        @fary=frame.split(eval('"'+dm+'"'))
        @v.msg{"Split:[#{frame}] by [#{dm}]" }
      else
        @fary=[frame]
      end
      @frame.set(@fary.shift)
      getfield_rec(@fdbs[:main])
      if cc=@field.delete('cc')
        cc == @cc || @v.err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
        @v.msg{"Verify:CC OK <#{cc}>"}
      end
    else
      @v.msg{"Send Only"}
      @fdbs[:select]=nil
    end
  end

  private
  def cut(e)
    @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
  end

  # Process Frame to Field
  def getfield_rec(e0)
    e0.each{|e1|
      case e1
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          @frame.mark
          getfield_rec(@fdbs[:ccrange])
          @cc = @frame.checkcode
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(@fdbs[:select])
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
      data=cut(e0)
      if key=e0['assign']
        @field[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
      if val=e0['val']
        val=eval(val).to_s if e0['decode']
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
        idxs << @par.subst(e1['range']) # Insert range depends on command param
      }
      @v.msg(1){"Array:#{e0['label']}[#{key}]:Range#{idxs}"}
      @field[key]=mk_array(idxs,@field[key]){
        cut(e0)
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
      fld[i] = mk_array(idx[1..-1],fld[i]){yield}
      @v.msg{"Array:Index[#{i}]=#{fld[i]}"}
    }
    fld
  end
end
