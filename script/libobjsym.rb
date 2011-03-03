#!/usr/bin/ruby
require "libxmldoc"
require "libsym"

class ObjSym < Sym
  def initialize(id)
    odb=XmlDoc.new('odb',id)
    super(odb,'status','ref')
  end
end
