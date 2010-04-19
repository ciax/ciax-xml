#!/usr/bin/ruby
require "libxmldb"
class ObjCtrl < XmlDb
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
