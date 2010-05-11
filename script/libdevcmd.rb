#!/usr/bin/ruby
require "libxmldev"
require "libvarfile"

class DevCmd < XmlDev
  def initialize(doc)
    super(doc,'//cmdframe')
    @f=VarFile.new(@property['id'])
  end

  def devcmd(par=nil)
    @var={'par'=>par}
    node_with_name('ccrange') do |e|
      @v.msg("Entering CC range",1)
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    end
    bin=get_string
    name="cmd_#{@id}"
    name+="_#{par}" if par
    @f.save_frame(name,bin)
  end
  
  def node_with_id!(id)
    unless super(id)
      list_id('./')
      raise ("No such a command")
    end
    @id=id
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
      @v.msg("[#{str.dump}]",1)
    end
    str
  end
  
  def encode(str)
    attr_with_key('type') do |type|
      case type
      when 'int'
        str=str.to_i
      when 'float'
        str=str.to_f
      end
    end
    attr_with_key('pack') do |pack|
      code=[str].pack(pack)
      hex=code.unpack('C*').map!{|c| '%02x' % c}.join
      @v.msg("pack(#{pack}) [#{str}] -> [#{hex}]",1)
      str=code
    end
    format(str)
  end

end



