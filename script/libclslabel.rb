#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"
require "libverbose"

class ClsLabel < Label
  def initialize(cls,id)
    @v=Verbose.new("Label")
    begin
      odb=XmlDoc.new('odb',id)
      super(odb,'status','ref','title')
      @v.msg{"using[#{id}] for object"}
    rescue SelectID
      cdb=XmlDoc.new('cdb',cls)
      super(cdb,'status','id')
      @v.msg{"using[#{cls}] for class"}
    end
  end
end
