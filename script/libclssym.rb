#!/usr/bin/ruby
require "libxmldoc"
require "libsym"

class ClsSym < Sym
  def initialize(id)
    cdb=XmlDoc.new('cdb',id)
    super(cdb,'status','id')
  end
end
