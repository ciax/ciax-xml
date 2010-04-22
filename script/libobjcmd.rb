#!/usr/bin/ruby
require "libxmldb"
require "libmodcmd"
class ObjCmd < XmlDb
  include ModCmd
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def objcmd
    warn "CommandExec[#{self['ref']}]"
  end
end




