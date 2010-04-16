#!/usr/bin/ruby
require "libobj"
TopNode='//controls'
class ObjCtrl < Obj
  public

  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
