#!/usr/bin/ruby
# included in Hash
class XmlVar < Hash
  def calCc(e,code)
    a=e.attributes
    chk=0
    case a['method']
    when 'len'
      chk=code.length
    when 'bcc'
      code.each_byte do |c|
        chk ^= c 
      end
    else
      raise "No such CC method #{a['method']}"
    end
    fmt=a['format'] || '%c'
    self[a['var']]=fmt % chk
    self
  end
  def getText(e)
    ref=e.attributes['ref']
    ref ? self[ref] : e.text
  end
  def trText(e,code)
    a=e.attributes
    code=eval "#{code}#{a['mask']}" if a['mask']
    code=[code].pack(a['pack']) if a['pack']
    code=code.unpack(a['unpack']).first if a['unpack']
    a['format'] ? a['format'] % code : code
  end
  def getStr(e)
    str=String.new
    e.elements.each do |d|
      case d.name
      when 'data'
        data=getText(d)
        str << trText(d,data)
      else
        str << self[d.name]
      end
    end
    str
  end
end
