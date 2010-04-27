#!/usr/bin/ruby
module ModCmd

  def node_with_id(id)
    msg "Select [#{id}]"
    if e=@doc.elements[".//[@id='#{id}']"]
      return copy_self(e)
    else
      list_id('./')
      raise ("No such a command")
    end
  end

end

