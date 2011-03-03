#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"

class FrmLabel < Label
  def initialize(id)
    fdb=XmlDoc.new('fdb',id)
    super(fdb,'rspframe','assign','field')
  end
end
