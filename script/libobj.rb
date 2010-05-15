#!/usr/bin/ruby
require "libobjcmd"
require "libobjstat"
require "libxmldoc"

class Obj
  attr_reader :stat,:property
  def initialize(obj)
    begin
      doc=XmlDoc.new('odb',obj)
      @oc=ObjCmd.new(doc)
      @os=ObjStat.new(doc)
    rescue RuntimeError
      abort $!.to_s
    end
    @property=doc.property
    @stat=@os.stat
  end

  def objcom(line)
    cmd,par=line.split(' ')
    c=@oc.node_with_id(cmd)
    c.objcmd(par) {|ccmd|
      if dstat=yield(ccmd)
        @oc.set_var!(dstat)
        @stat=@os.objstat(dstat)
      end
    }
  end
end
