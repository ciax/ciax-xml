#!/usr/bin/ruby
require "libxmldoc"
require "libsymconv"

class ClsSym < SymConv
  def initialize(id)
    cdb=XmlDoc.new('cdb',id)
    super(cdb,'status','id')
  end
end
