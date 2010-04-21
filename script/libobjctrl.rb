#!/usr/bin/ruby
require "libxmldb"
require "libctrl"
class ObjCtrl < XmlDb
  include Ctrl
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def objctrl
    warn "CommandExec[#{self['ref']}]"
  end
end
