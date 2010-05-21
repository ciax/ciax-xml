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
    @var={:par=>par}
    if par
      @property['par']=par
    else
      @property.delete('par')
    end
  end    

  def devcmd
    node_with_name('ccrange') {|e|
      @v.msg("Entering CC range")
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    }
    get_string
  end

  def cmd_id
    super('snd')
  end

  protected
  def get_string
    str=String.new
    each_node {|d|
      case d.name
      when 'data'
        str << encode(d,d.text)
      when 'cc_cmd'
        str << encode(d,@var[:ccc])
      when 'par'
        str << encode(d,@var[:par])
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
      @v.msg("GetCmdString: [#{str.dump}]")
    }
    str
  end
  
  def encode(e,str)
    if type=e.attr['type']
      case type
      when 'int'
        str=str.to_i
      when 'float'
        str=str.to_f
      end
    end
    if pack=e.attr['pack']
      code=[str].pack(pack)
      @v.msg("Encode:pack(#{pack}) [#{str}] -> [#{code}]")
      str=code
    end
    e.format(str)
  end

end
