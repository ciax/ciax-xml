#!/usr/bin/ruby
require "libxmldoc"
require "libsym"
require "libverbose"

class ClsSym
  def initialize(id)
    @v=Verbose.new("Sym")
    cdb=XmlDoc.new('cdb',id)
    @cs=Sym.new(cdb,'status','id')
    @v.msg{"using[#{id}]for class"}
    begin
      odb=XmlDoc.new('odb',id)
      @os=Sym.new(odb,'status','ref')
      @v.msg{"using[#{id}] for object"}
    rescue SelectID
    end
  end

  def convert(stat)
    res=@cs.convert(stat)
    res=@os.overwrite(res) if @os
    res
  end
end
