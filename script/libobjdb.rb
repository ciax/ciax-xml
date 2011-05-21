#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"
require "libsymdb"

class ObjDb < ClsDb
  attr_reader :alias
  def initialize(obj,cls=nil)
    @alias={}
    @status={}
    @symtbl={}
    super(cls) if cls
    doc=XmlDoc.new('odb',obj)
    doc.find_each('command','alias'){|e0|
      e0.attr2db(@alias)
    }
    @status[:label]={}
    doc.find_each('status','title'){|e0|
      e0.attr2db(@status,'ref')
    }
    SymDb.new(doc,@symtbl)
  rescue SelectID
  end
end
