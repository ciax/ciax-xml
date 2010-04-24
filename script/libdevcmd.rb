#!/usr/bin/ruby
require "libmoddev"
require "libxmldb"
class DevCmd < XmlDb
  include ModDev
  def initialize(doc)
    super(doc,'//cmdframe')
  end

  def devcmd(par=nil)
    @var['par']=par
    node_with_name('ccrange') do |e|
      msg("Entering CC range",1)
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    end
    yield get_string
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
      msg "[#{str.dump}]"
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
      msg "pack(#{pack}) [#{str}] -> [#{hex}]"
      str=code
    end
    format(str)
  end

end



