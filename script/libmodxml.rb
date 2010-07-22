#!/usr/bin/ruby
# XML Common Method
require 'libnumrange'
module ModXml
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
    return format(e,code)
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
    str || @v.err("No Parameter")
    @v.msg{"Validate String [#{str}]"}
    case e.attributes['validate']
    when 'regexp'
      /^#{e.text}$/ === str || @v.err("Parameter invalid(#{e.text})")
    when 'range'
      e.text.split(',').any? { |s|
        NumRange.new(s) == str
      } || @v.err("Parameter out of range(#{e.text})")
    end
    str
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      @v.msg{"Formatted code(#{fmt}) [#{code}] -> [#{str}]"}
      code=str
    end
    code.to_s
  end

  def substitute(e,hash) # Substitute ${id} by hash[id]
    str=e.text
    return str if /\$\{[\w:]+\}/ !~ str
    conv=str.gsub(/\$\{([\w:]+)\}/) { 
      h=hash.clone
      $1.split(':').each { |i| h=(Array === h) ? h[i.to_i] : h[i] }
      h
    }
    @v.msg{"Substitute [#{str}] to [#{conv}]"}
    conv
  end

  def repeat(e)
    Range.new(*e.attributes['range'].split(':')).each { |n|
      e.each_element { |d| yield d,n }
    }
  end

  def text(e) # convert escape char (i.e. "\n"..)
    eval('"'+e.text+'"') if e.text
  end

  def attr(e,attr) # convert escape char (i.e. "\n"..)
    eval('"'+e.attributes[attr]+'"') if e.attributes[attr]
  end
end
