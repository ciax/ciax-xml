#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libmodsym"

class SymDb < Hash
  include ModSym
  def initialize
    @v=Verbose.new("sym")
    @doc=XmlDoc.new('sdb','all')
    update init_sym
  end
end
