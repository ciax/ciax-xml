#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def devcmd
    node_with_name('ccrange') do |e|
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    end
    get_string
  end
  
  def get_field(field)
    @var.update(field)
  end

  protected
  def get_string
    str=String.new
    each do |d|
      case d.name
      when 'data'
        str << d.encode(d.text)
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
    end
    str
  end
  
  def encode(str)
    attr?('operator') do |ope|
      x=str.to_i
      y=@doc.text.hex
      case ope
        when 'and'
        str=x & y
        when 'or'
        str=x | y
      end
        @v.msg "(#{x} #{ope} #{y})=#{str}"
    end
    @doc.attributes.each do |key,val|
      case key
      when 'pack'
        code=[str].pack(val)
        hex=code.unpack('C*').map!{|c| '%02x' % c}.join
        @v.msg "pack(#{val}) [#{str}] -> [#{hex}]"
        str=code
      when 'format'
        str=val % str
      end
    end
    str
  end

end
