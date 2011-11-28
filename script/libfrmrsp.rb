#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libiocmd"

# Rsp Methods
class FrmRsp < Field
  def initialize(fdb,par)
    @v=Msg::Ver.new("frm/rsp",3)
    @fdb=Msg.type?(fdb,FrmDb)
    @par=Msg.type?(par,Command)
    super(fdb['id'])
    rsp=fdb[:rspframe]
    @sel=Hash[rsp[:frame]]
    @fds=rsp[:select]
    @frame=Frame.new(fdb['endian'],fdb['ccmethod'])
    rsp[:assign].each{|k,v|
      self[k]||=v
    }
  end

  # Block accepts [time,frame]
  def upd
    if rid=@par[:response]
      @sel[:select]=@fds[rid]|| Msg.err("No such response id [#{rid}]")
      frame,self['time']=yield
      Msg.err("No Response") unless frame
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
      if cc=delete('cc') # self.delete
        cc == @cc || Msg.err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
        @v.msg{"Verify:CC OK <#{cc}>"}
      end
    else
      @v.msg{"Send Only"}
      @sel[:select]=nil
    end
    @v.msg{"Update at #{self['time']}"}
    self
  end

  def upd_logline(str)
    cmd,res=IoLog.set_logline(str)
    @par.set(cmd)
    upd{res}
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
        self[key]=mk_array(idxs,self[key]){yield}
      ensure
        @v.msg(-1){"Array:Assign[#{key}]"}
      end
    else
      #Field
      data=yield
      if key=e0['assign']
        self[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
    end
  ensure
    @v.msg(-1){"Field:End"}
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

  def cut(e)
    @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
  end
end

if __FILE__ == $0
  require "libfrmdb"
  require "libcommand"
  fid=ARGV.shift
  begin
    fdb=FrmDb.new(fid)
    par=Command.new(fdb[:cmdframe])
    field=FrmRsp.new(fdb,par)
    str=gets(nil) || exit
    field.upd_logline(str)
    puts field.to_j
  rescue UserError
    warn "Usage: #{$0} [frameID] < logline"
    Msg.exit
  end
end
