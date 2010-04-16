#!/usr/bin/ruby
require "libobj"
TopNode='//controls'
class ObjCtrl < Obj
  public
  def set_cmd(id)
    begin
      @doc=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      list_id(TopNode)
      raise("No such a command")
    end
  end

  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
