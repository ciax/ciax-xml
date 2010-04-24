#!/usr/bin/ruby
module ModCmd

  def node_with_id(id)
    msg "Select [#{id}]"
    begin
      e=@doc.elements[".//[@id='#{id}']"] || raise
    rescue
      list_id('./')
      raise("No such a command")
    end
    copy_self(e)
  end

end

