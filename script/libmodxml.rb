#!/usr/bin/ruby
# XML Common Method
module ModXml
  # Instance variable: @v

  def checkcode(e,frame)
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
      @v.msg{"Calc:CC [#{method.upcase}] -> [#{chk}]"}
      return chk.to_s
    end
    @v.err("CC No method")
  end

  Codec={'hexstr'=>'hex','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code)
    cdc=e['decode']
    if upk=Codec[cdc]
      str=(upk == 'hex') ? code.hex : code.unpack(upk).first
      @v.msg{"Decode:(#{cdc}) [#{code}] -> [#{str}]"}
      code=str
    end
    return code.to_s
  end

  def encode(e,str)
    cdc=e['encode']
    if pck=Codec[cdc]
      code=[str.to_i(0)].pack(pck)
      @v.msg{"Encode:(#{cdc}) [#{str}] -> [#{code}]"}
      str=code
    end
    format(e,str)
  end

  def format(e,code)
    if fmt=e['format']
      str=fmt % code
      @v.msg{"Formatted code(#{fmt}) [#{code}] -> [#{str}]"}
      code=str
    end
    code.to_s
  end

end
