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
end
