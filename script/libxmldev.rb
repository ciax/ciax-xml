#!/usr/bin/ruby
require "libxmldb"

class XmlDev < XmlDb
  attr_reader :property
  def initialize(doc,xpath)
    id=doc.property['id']
    super(doc,xpath,"#{doc.root.name}/#{id}".upcase)
    @property={'id'=>id}
    @var=Hash.new
  end

  # Public Method
  public
  def cmd_id(str)
    [str,@property['cmd'],@property['par']].compact.join('_')
  end

  def each_node(xpath=nil)
    super(xpath) {|e|
      if e.name == 'select'
        @v.err "ID not selected" unless @sel
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
      chk=chk.to_s
      @v.msg("Calc:CC [#{method.upcase}] -> [#{chk}]")
      @var[:ccc] = chk
      return chk
    end
    @v.err "CC No method"
  end

end
