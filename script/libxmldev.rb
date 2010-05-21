#!/usr/bin/ruby
require "libxmldb"

class XmlDev < XmlDb
  attr_reader :property
  def initialize(doc,xpath)
    super(doc,"#{doc.root.name}/#{doc.property['id']}".upcase)
    set_xpath!(xpath)
    @property={'id'=>doc.property['id']}
  end

  # Public Method
  public
  def setcmd(cmd)
    @sel=elem_with_id(cmd)
    @property['cmd']=cmd
    self
  end

  def cmd_id(str)
    [str,@property['cmd'],@property['par']].compact.join('_')
  end

  def each_node
    super {|e|
      if e.name == 'select'
        @v.err "ID not selected" unless @sel
        @v.msg("Enterning Select Node")
        @sel.elements.each {|s| yield copy_self(s) }
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
      set_var!({:ccc => chk})
      return chk
    end
    @v.err "CC No method"
  end

end
