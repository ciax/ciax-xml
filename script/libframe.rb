#!/usr/bin/ruby
class Frame
  def initialize(endian=nil) # delimiter,terminator
    @v=Verbose.new("fdb/frm".upcase,6)
    @endian=endian
    @fp=@mark=0
    @frame=''
  end

  def add(frame)
    @v.msg{"Frame add [#{frame}]"}
    @frame << frame
    self
  end

  def mark
    @v.msg{"Mark FP:[#{@fp}]" }
    @mark=@fp
    self
  end

  def copy
    @v.msg{"Copy Frame from [#{@mark}-#{@fp}]"}
    @frame.slice(@mark...@fp)
  end

  def cut(e0)
    rest=@frame.size-@fp
    return nil unless rest > 0
    len=e0['length']||rest
    str=@frame.slice(@fp,len.to_i)
    @fp+=len.to_i
    @v.msg{"CutFrame: <#{str}> by size=[#{len}]"}
    if r=e0['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame: <#{str}> by range=[#{r}]"}
    end
    decode(e0,str)
  end

  private
  def decode(e,code) # Chr -> Num
    return code.to_s unless cdc=e['decode']
    if cdc == 'hexstr'
      num=code.hex
    else
      ary=code.unpack("C*")
      ary.reverse! if @endian=='little'
      num=ary.inject(0){|r,i| r*256+i}
      if cdc=='signed'
        p= 256 ** code.size
        num = num < p/2 ? num : num - p
      end
    end
    @v.msg{"Decode:(#{cdc}) [#{code}] -> [#{num}]"}
    num.to_s
  end
end
