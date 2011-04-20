#!/usr/bin/ruby
module FrmMod
  # Instance variable: @v

  def checkcode(e,frame)
    @v.msg{"CC Frame <#{frame}>"}
    chk=0
    if method=e['method']
      case method
      when 'len'
        chk=frame.length
      when 'bcc'
        frame.each_byte {|c| chk ^= c }
      when 'sum'
        frame.each_byte {|c| chk += c }
        chk%=256
      else
        @v.err("No such CC method #{method}")
      end
      @v.msg{"Calc:CC [#{method.upcase}] -> (#{chk})"}
      return chk.to_s
    end
    @v.err("CC No method")
  end

  Codec={'hexstr'=>'hex','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code) # Chr -> Num
    cdc=e['decode']
    if upk=Codec[cdc]
      num=(upk == 'hex') ? code.hex : code.unpack(upk).first
      @v.msg{"Decode:(#{cdc}) [#{code}] -> [#{num}]"}
      code=num
    end
    return code.to_s
  end

  def encode(e,str) # Num -> Chr
    cdc=e['encode']
    if pck=Codec[cdc]
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
