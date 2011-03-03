#!/usr/bin/ruby
require "libxmldoc"
require "libsym"

class FrmSym < Sym
  def initialize(id)
    fdb=XmlDoc.new('fdb',id)
    super(fdb,'rspframe','assign','field')
  end
end
