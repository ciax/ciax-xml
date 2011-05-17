#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"
require "libsymdb"

class ObjDb < ClsDb
  def initialize(cls,obj)
    super(cls)
    doc=XmlDoc.new('odb',obj)
    doc.find_each('command','alias'){|e0|
      e0.attr2db(self[:command]){|v|v}
    }
    doc.find_each('status','title'){|e0|
      e0.attr2db(self[:status],'ref'){|v|v}
    }
    self[:symtbl].update(SymDb.new(doc))
  rescue SelectID
  end
end
