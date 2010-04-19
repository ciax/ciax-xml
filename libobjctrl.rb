#!/usr/bin/ruby
require "libobj"
class ObjCtrl < Obj
  public

  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
