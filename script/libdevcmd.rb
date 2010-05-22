#!/usr/bin/ruby
require "libxmldev"

class DevCmd < XmlDev
  attr_reader :property

  def initialize(doc)
    super(doc,'//cmdframe')
  end

  def setcmd(id)
    @sel=@doc.select_id('//cmdframe/',id)
    @property['cmd']=id
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
    cid=cmd_id
    return @var[cid] if @var[cid]
    each_node('./ccrange') {|e|
      @v.msg("Entering CC range")
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    }
    @var[cid]=get_string
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
        str << d.encode(d.text)
      when 'cc_cmd'
        str << d.encode(@var[:ccc])
      when 'par'
        str << d.validation(@var[:par])
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
      @v.msg("GetCmdString: [#{str.dump}]")
    }
    str
  end

  def validation(str)
    if v=attr['valid']
      raise "No parameter" unless str
      raise "Parameter invalid" unless /^#{v}$/ =~ str
    end
    encode(str)
  end

  def encode(str)
    if type=attr['type']
      case type
      when 'int'
        str=str.to_i
      when 'float'
        str=str.to_f
      end
    end
    if pack=attr['pack']
      code=[str].pack(pack)
      @v.msg("Encode:pack(#{pack}) [#{str}] -> [#{code}]")
      str=code
    end
    format(str)
  end

end
