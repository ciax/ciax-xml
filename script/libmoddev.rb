#!/usr/bin/ruby
module ModDev
  # Public Method
  public
  def node_with_id!(id)
    @sel=@doc.elements[".//[@id='#{id}']"] || return
  end

  def each_node
    super do |e|
      if e.name == 'select'
        err "ID not selected" unless @sel
        msg("Enterning Select",1)
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
        err "No such CC method #{method}"
      end
      val=format(chk)
      msg "[#{method.upcase}] -> [#{val}]"
      set_var!({'cc' => val})
      return self
    end
    err "No method"
  end

end
