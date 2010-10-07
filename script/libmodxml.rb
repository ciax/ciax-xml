#!/usr/bin/ruby
# XML Common Method
require 'librerange'
module ModXml
  # Instance variable: @v,@n

  def checkcode(e,frame)
    chk=0
    if method=e.attributes['method']
      case method
      when 'len'
        chk=frame.length
      when 'bcc'
        frame.each_byte {|c| chk ^= c }
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
    cdc=e.attributes['decode']
    if upk=Codec[cdc]
      str=(upk == 'hex') ? code.hex : code.unpack(upk).first
      @v.msg{"Decode:(#{cdc}) [#{code}] -> [#{str}]"}
      code=str
    end
    return code.to_s
  end

  def encode(e,str)
    cdc=e.attributes['encode']
    if pck=Codec[cdc]
      code=[str.to_i(0)].pack(pck)
      @v.msg{"Encode:(#{cdc}) [#{str}] -> [#{code}]"}
      str=code
    end
    format(e,str)
  end

  def validate(e,str)
    str || @v.err("Too Few Parameters#{yield}")
    @v.msg{"Validate: String for [#{str}]"}
    e.each_element {|d|
      @v.msg{"Validate: Match? [#{d.text}]"}
      case d.name
      when 'regexp'
        return(str) if /^#{d.text}$/ === str
      when 'range'
        return(str) if ReRange.new(d.text) == str
      end
    }
    @v.err("Parameter invalid(#{e.attributes['label']})")
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      @v.msg{"Formatted code(#{fmt}) [#{code}] -> [#{str}]"}
      code=str
    end
    code.to_s
  end

end
