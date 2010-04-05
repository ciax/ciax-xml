#!/usr/bin/ruby
module XmlTxt
  def trText(e,code)
    a=e.attributes
    code=eval "#{code}#{a['mask']}" if a['mask']
    code=[code].pack(a['pack']) if a['pack']
    code=code.unpack(a['unpack']).first if a['unpack']
    a['format'] ? a['format'] % code : code
  end
end
