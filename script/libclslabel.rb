#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"

class ClsLabel < Label
  def initialize(type,id)
    cdb=XmlDoc.new('cdb',type)
    super(cdb,'status','id')
    begin
      odb=XmlDoc.new('odb',id)
      super(odb,'status','ref','title')
    rescue SelectID
    end
  end
end
