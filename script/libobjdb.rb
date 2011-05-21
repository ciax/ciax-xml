#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"
require "libsymdb"

class ObjDb < ClsDb
  attr_reader :alias
  def initialize(obj,cls=nil)
    if cls
      super(cls)
      begin
        doc=XmlDoc.new('odb',obj)
      rescue SelectID
        doc=nil
      end
    else
      @status={}
      @symtbl={}
      doc=XmlDoc.new('odb',obj)
    end
    @alias={}
    if doc
      doc.find_each('command','alias'){|e0|
        e0.attr2db(@alias)
      }
      @status[:label]={}
      doc.find_each('status','title'){|e0|
        e0.attr2db(@status,'ref')
      }
      SymDb.new(doc,@symtbl)
    end
  end
end
