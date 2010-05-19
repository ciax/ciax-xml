#!/usr/bin/ruby
require "libxmldb"

class XmlDev < XmlDb
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
      val=format(chk)
      @v.msg("Check Code [#{method.upcase}] -> [#{val}]")
      set_var!({'cc' => val})
      return val
    end
    @v.err "No method"
  end

end
