#!/usr/bin/ruby
# included in String
module XmlText
  def initialize(str = '')
    @var=Hash.new
    super(str)
  end
  def calCc(e)
    a=e.attributes
    chk=0
    case a['method']
    when 'len'
      chk=self.length
    when 'bcc'
      self.each_byte do |c|
        chk ^= c 
      end
    else
      raise "No such CC method #{a['method']}"
    end
    fmt=a['format'] || '%c'
    @var[a['var']]=fmt % chk
    self
  end
  def getText(e)
    ref=e.attributes['ref']
    ref ? @var[ref] : e.text
  end
  def trText(e,code)
    a=e.attributes
    code=eval "#{code}#{a['mask']}" if a['mask']
    code=[code].pack(a['pack']) if a['pack']
    code=code.unpack(a['unpack']).first if a['unpack']
    a['format'] ? a['format'] % code : code
  end
  def getStr(e)
    clear
    e.elements.each do |d|
      case d.name
      when 'data'
        data=getText(d)
        self << trText(d,data)
      else
        self << @var[d.name]
      end
    end
    self
  end
end
