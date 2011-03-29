#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"
require "libverbose"

class ClsLabel < Label
  def initialize(cls,id)
    @v=Verbose.new("Label")
    cdb=XmlDoc.new('cdb',cls)
    super(cdb,'status','id')
    @v.msg{"using[#{cls}] for class"}
    begin
      odb=XmlDoc.new('odb',id)
      @odb=Label.new(odb,'status','ref')
      @v.msg{"using[#{id}] for object"}
    rescue SelectID
      @v.msg{"No [#{id}] for object"}
    end
  end

  def merge(stat)
    res=super(stat)
    res=@odb.merge(res) if @odb
    res
  end

end
