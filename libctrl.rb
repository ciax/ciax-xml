#!/usr/bin/ruby
module Ctrl

  def node_with_id(id)
    begin
      e=@doc.elements[".//[@id='#{id}']"] || raise
    rescue
      list_id('./')
      raise("No such a command")
    end
    copy_self(e)
  end

end
