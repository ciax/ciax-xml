#!/usr/bin/ruby
require "libxmldb"

class XmlDev < XmlDb
  # Public Method
  public
  def node_with_id!(id)
    @sel=elem_with_id(id)
    @property['cmd']=id
    self
  end

  def each_node
    super {|e|
      if e.name == 'select'
        @v.err "ID not selected" unless @sel
        @v.msg("Enterning Select",1)
        @sel.elements.each {|s| yield copy_self(s) }
      else
        yield e
      end
    }
  end

  def checkcode(str)
    chk=0
    attr_with_key('method') {|method|
      case method
      when 'len'
        chk=str.length
      when 'bcc'
        str.each_byte {|c| chk ^= c } 
      else
        @v.err "No such CC method #{method}"
      end
      val=format(chk)
      @v.msg("[#{method.upcase}] -> [#{val}]",1)
      set_var!({'cc' => val})
      return self
    }
    @v.err "No method"
  end

end
