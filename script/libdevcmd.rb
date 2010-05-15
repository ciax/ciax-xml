#!/usr/bin/ruby
require "libxmldev"

class DevCmd < XmlDev
  attr_reader :property

  def initialize(doc)
    super(doc,'//cmdframe')
  end

  def setcmd(id)
    begin
      super(id)
    rescue
      list_id('./')
      raise ("No such a command")
    end
    self
  end

  def setpar(par=nil)
    @var={'par'=>par}
    if par
      @property['par']=par
    else
      @property.delete('par')
    end
  end    

  def devcmd
    node_with_name('ccrange') {|e|
      @v.msg("Entering CC range",1)
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    }
    get_string
  end

  def file_id
    super('snd')
  end

  protected
  def get_string
    str=String.new
    each_node {|d|
      case d.name
      when 'data'
        str << d.encode(d.text)
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
      @v.msg("[#{str.dump}]",1)
    }
    str
  end
  
  def encode(str)
    attr_with_key('type') {|type|
      case type
      when 'int'
        str=str.to_i
      when 'float'
        str=str.to_f
      end
    }
    attr_with_key('pack') {|pack|
      code=[str].pack(pack)
      hex=code.unpack('C*').map!{|c| '%02x' % c}.join
      @v.msg("pack(#{pack}) [#{str}] -> [#{hex}]",1)
      str=code
    }
    format(str)
  end

end
