#!/usr/bin/ruby
class Frame
  def initialize(endian=nil,ccmethod=nil) # delimiter,terminator
    @v=Verbose.new("fdb/frm".upcase,6)
    @endian=endian
    @method=ccmethod
    @fp=@mark=0
    @frame=''
  end

  def set(frame='')
    if frame
      @v.msg{"Frame set <#{frame}>"}
      @frame=frame
      @fp=@mark=0
    end
    self
  end

  def add(frame,e={})
    if frame
      code=encode(e,frame)
      @frame << code
      @fp += code.size
      @v.msg{"Frame add <#{frame}> (#{@fp})"}
    end
    self
  end

  def mark
    @v.msg{"Mark FP:(#{@fp})" }
    @mark=@fp
    self
  end

  def copy
    str=@frame.slice(@mark...@fp)
    @v.msg{"Copy Frame <#{str}> (#{@mark}-#{@fp})"}
    str
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

  def checkcode
    frame=copy
    @v.msg{"CC Frame <#{frame}>"}
    chk=0
    case @method
    when 'len'
      chk=frame.length
    when 'bcc'
      frame.each_byte {|c| chk ^= c }
    when 'sum'
      frame.each_byte {|c| chk += c }
      chk%=256
    else
      @v.err("No such CC method #{@method}")
    end
    @v.msg{"Calc:CC [#{@method.upcase}] -> (#{chk})"}
    return chk.to_s
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
end
