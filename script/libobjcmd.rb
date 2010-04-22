#!/usr/bin/ruby
require "libxmldb"
require "libmodcmd"
class ObjCmd < XmlDb
  include Ctrl
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def objcmd
    warn "CommandExec[#{self['ref']}]"
  end
end



