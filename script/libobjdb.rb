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
      e0.attr2db(@command){|v|v}
    }
    doc.find_each('status','title'){|e0|
      e0.attr2db(@status,'ref'){|v|v}
    }
    @symtbl.update(SymDb.new(doc))
  rescue SelectID
  end
end
