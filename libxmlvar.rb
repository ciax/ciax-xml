#!/usr/bin/ruby
# included in Hash
class XmlVar < Hash
  attr_reader :ccstr,:ref
  def initialize(hash=nil)
    @ccstr=String.new
    @ref=String.new
    super(hash)
  end
  def calCc(e,str)
    a=e.attributes
    chk=0
    case a['method']
    when 'len'
      chk=str.length
    when 'bcc'
      str.each_byte do |c|
        chk ^= c 
      end
    else
      raise "No such CC method #{a['method']}"
    end
    fmt=a['format'] || '%c'
    self[a['var']]=fmt % chk
    @ccstr=str
  end
  def getText(e)
    return e.text unless r=e.attributes['ref']
    if self[r]
      return self[r]
    else
      raise "No reference for [#{r}]"
    end
  end
end
