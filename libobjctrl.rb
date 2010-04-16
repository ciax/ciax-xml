#!/usr/bin/ruby
require "libobj"
TopNode='//controls'
class ObjCtrl < Obj
  public
  def set_cmd(id)
    @doc=super(id)
  end

  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
