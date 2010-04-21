#!/usr/bin/ruby
require "libdev"
require "libctrl"
class DevCtrl < Dev
  def initialize(doc)
    super(doc,'//cmdframe')
  end

  def devctrl(par=nil)
    @var['par']=par
    node_with_name('ccrange') do |e|
      @v.msg("Entering CC range",1)
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    end
    get_string
  end
  
  def node_with_id!(id)
    begin
      super(id)
    rescue
      list_id('./')
      raise("No such a command")
    end
    self
  end

  protected
  def get_string
    str=String.new
    each_node do |d|
      case d.name
      when 'data'
        str << d.encode(d.text)
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
      @v.msg "[#{str.dump}]"
    end
    str
  end
  
  def encode(str)
    attr_with_key('operator') do |ope|
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
    attr_with_key('pack') do |val|
      if /[aAbBhHpPuUwWzZ]/=~val
        code=[str].pack(val)
      else
        code=[str.to_i].pack(val)
      end
      hex=code.unpack('C*').map!{|c| '%02x' % c}.join
      @v.msg "pack(#{val}) [#{str}] -> [#{hex}]"
      str=code
    end
    format(str)
  end

end
