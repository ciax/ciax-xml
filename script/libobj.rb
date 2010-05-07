#!/usr/bin/ruby
require "libobjcmd"
require "libobjstat"
require "libxmldoc"

class Obj
  attr_reader :stat,:property
  def initialize(obj)
    begin
      doc=XmlDoc.new('odb',obj)
      @cc=ObjCmd.new(doc)
      @cs=ObjStat.new(doc)
    rescue RuntimeError
      abort $!.to_s
    end
    @property=@cc.property
  end
  
  def stat
    @cs.stat
  end

  def objcom(cmd,par=nil)
    begin
      c=@cc.node_with_id(cmd)
    rescue
      puts $!
      return
    end
    c.objcmd(par) do |ccmd|
      dstat=yield ccmd
      @cc.set_var!(dstat)
      @cs.objstat(dstat) if dstat
    end
  end
end





