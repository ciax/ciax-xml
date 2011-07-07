#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"
require "libsymdb"

class ObjDb < ClsDb
  attr_reader :alias
  def initialize(obj,cls=nil) # cls can be gotten from odb, otherwise DB-object
    @alias={}
    @status={}
    @tables={}
    super(cls) if cls
    doc=XmlDoc.new('odb',obj)
    doc.domain('command').each('alias'){|e0|
      e0.attr2db(@alias)
    }
    @status[:label]={}
    doc.domain('status').each('title'){|e0|
      e0.attr2db(@status,'ref')
    }
    SymDb.new(doc,@tables)
  rescue SelectID
  end
end
