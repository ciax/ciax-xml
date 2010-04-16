#!/usr/bin/ruby
require "libxmldb"
class Dev < XmlDb
  def initialize(dev)
    super('ddb',dev)
  end

  # Public Method
  public
  def node_with_id!(id)
    @sel=node_with_id(id).doc
    self
  end

  def each_node
    super do |e|
      if e.name == 'select'
        raise "ID not selected" unless @sel
        @v.msg("Enterning Select",1)
        @sel.elements.each do |s|
          yield copy_self(s)
        end
      else
        yield e
      end
    end
  end

  def checkcode(str)
    method=self['method']
    chk=0
    case method
    when 'len'
      chk=str.length
    when 'bcc'
      str.each_byte {|c| chk ^= c } 
    else
      raise "No such CC method #{method}"
    end
    val=format(chk)
    @v.msg "[#{method.upcase}] -> [#{val}]"
    @var[self['var']]=val
  end

end



