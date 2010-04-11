#!/usr/bin/ruby
require "libxmldb"
class Dev < XmlDb
  def initialize(dev,cmd)
    begin
      super('ddb',dev)
      select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end

  def calc_cc(str)
    a=@doc.attributes
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
    val=(fmt % chk).to_s
    @v.msg "[#{a['method']}/#{a['format']}] -> [#{val}]"
    {a['var'] => val}
  end
end
