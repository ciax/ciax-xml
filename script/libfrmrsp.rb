#!/usr/bin/ruby
require "libframe"
require "libparam"

# Rsp Methods
class FrmRsp
  def initialize(fdb,field)
    @fdb=fdb
    @field=field
    @v=Msg::Ver.new("#{fdb['id']}/rsp",3)
    @field['frm_type']=fdb['id']
    @sel=Hash[fdb[:frame][:status]]
    @par=Param.new(fdb[:command],:frame)
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
  end

  # Block accepts [time,frame]
  def setrsp(cmd)
    if rid=@par.set(cmd)[:response]
      @sel[:select]=@par[:frame]|| Msg.err("No such response id [#{rid}]")
      @v.msg{"Set Statement #{cmd}"}
      time,frame=yield
      Msg.err("No Response") unless frame
      @field['time']="%.3f" % time.to_f
      if tm=@sel['terminator']
        frame.chomp!(eval('"'+tm+'"'))
        @v.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
      end
      if dm=@sel['delimiter']
        @fary=frame.split(eval('"'+dm+'"'))
        @v.msg{"Split:[#{frame}] by [#{dm}]" }
      else
        @fary=[frame]
      end
      @frame.set(@fary.shift)
      getfield_rec(@sel[:main])
      if cc=@field.delete('cc')
        cc == @cc || Msg.err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
        @v.msg{"Verify:CC OK <#{cc}>"}
      end
    else
      @v.msg{"Send Only"}
      @sel[:select]=nil
    end
  end

  private
  def cut(e)
    @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
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

  def frame_to_field(e0)
    @v.msg(1){"Field:#{e0['label']}"}
    if e0[:index]
      # Array
      key=e0['assign'] || Msg.err("No key for Array")
      # Insert range depends on command param
      idxs=e0[:index].map{|e1|
        @par.subst(e1['range'])
      }
      begin
        @v.msg(1){"Array:[#{key}]:Range#{idxs}"}
        @field[key]=mk_array(idxs,@field[key]){yield}
      ensure
        @v.msg(-1){"Array:Assign[#{key}]"}
      end
    else
      #Field
      data=yield
      if key=e0['assign']
        @field[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
    end
  ensure
    @v.msg(-1){"Field:End"}
  end

  # Process Frame to Field
  def getfield_rec(e0)
    e0.each{|e1|
      case e1
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          @frame.mark
          getfield_rec(@sel[:ccrange])
          @cc = @frame.checkcode
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(@sel[:select])
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when Hash
        frame_to_field(e1){ cut(e1) }
      end
    }
  end
end

if __FILE__ == $0
  require "libfield"
  require "libfrmdb"
  args=ARGV.partition{|s| /^-/ === s}
  opt=args.shift.join('')
  dev=args.shift.first
  ARGV.clear
  begin
    fdb=FrmDb.new(dev,true)
    field=Field.new
    r=FrmRsp.new(fdb,field)
    str=gets(nil) || exit
    ary=str.split("\t")
    time=Time.at(ary.shift.to_f)
    stm=ary.shift.split(':')
    abort ("Logline:Not response") unless /rcv/ === stm.shift
    r.setrsp(stm){[time,eval(ary.shift)]}
    puts field.to_j
  rescue RuntimeError
    if opt.include?('q')
      exit 1
    else
      abort "Usage: #{$0} (-q) [frame] < logline\n#{$!}"
    end
  end
end

