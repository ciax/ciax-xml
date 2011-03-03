#!/usr/bin/ruby
require "libxmldoc"
require "libsymconv"

class FrmSym < SymConv
  def initialize(id)
    fdb=XmlDoc.new('fdb',id)
    super(fdb,'rspframe','assign','field')
  end
end
