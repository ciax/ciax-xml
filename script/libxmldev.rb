#!/usr/bin/ruby
require "libxmldb"

class XmlDev < XmlDb
  attr_reader :property
  def initialize(doc,xpath)
    id=doc.property['id']
    super(doc,xpath,"#{doc.root.name}/#{id}/#{xpath.delete('/')}".upcase)
    @property={'id'=>id}
    @var=Hash.new
  end

  # Public Method
  public
  def setcmd(id,chld)
    @sel=@doc.select_id('//session/',id).elements[chld] || raise("No [#{chld}]")
    @property['cmd']=id
    self
  end

  def cmd_id(str)
    [str,@property['cmd'],@property['par']].compact.join('_')
  end

  def each_node(xpath=nil)
    super(xpath) {|e|
      if e.name == 'select'
        @v.msg "Read Only" unless @sel
        @v.msg("Enterning Select Node")
        @sel.each_element {|s| yield copy_self(s) }
      else
        yield e
      end
    }
  end

  def checkcode(str)
    chk=0
    if method=attr['method']
      case method
      when 'len'
        chk=str.length
      when 'bcc'
        str.each_byte {|c| chk ^= c } 
      else
        @v.err "No such CC method #{method}"
      end
      @v.msg("Calc:CC [#{method.upcase}] -> [#{chk}]")
      @var[:ccc] = chk.to_s
      return chk
    end
    @v.err "CC No method"
  end

end
