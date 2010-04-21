#!/usr/bin/ruby
require "libxmldb"
class Dev < XmlDb
  # Public Method
  public
  def node_with_id!(id)
    @sel=@doc.elements[".//[@id='#{id}']"] || raise
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
    chk=0
    attr_with_key('method') do |method|
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
      set_var!({self['var'] => val})
      return self
    end
    raise "No method"
  end

end
