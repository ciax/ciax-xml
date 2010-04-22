#!/usr/bin/ruby
require "libxmldb"
require "libctrl"
class ObjCtrl < XmlDb
  include Ctrl
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def objcmd
    warn "CommandExec[#{self['ref']}]"
  end
end

