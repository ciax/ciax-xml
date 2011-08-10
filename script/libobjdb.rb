#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"
require "libsymdb"

class ObjDb < ClsDb
  attr_reader :alias
  def initialize(obj,cls=nil) # cls can be gotten from odb, otherwise DB-object
    if cls
      super(cls)
      self['class']=cls
    else
      @command={}
      @status={}
      @tables={}
    end
    self['id']=obj
    @alias={}
    doc=XmlDoc.new('odb',obj)
    doc.domain('command').each('alias'){|e0|
      e0.attr2db(@alias)
    }
    @status[:label]||={}
    doc.domain('status').each('title'){|e0|
      e0.attr2db(@status,'ref')
    }
    @tables.update(SymDb.new(doc))
  rescue SelectID
    raise SelectID,$!.to_s if __FILE__ == $0
  end

  def to_s
    super+Verbose.view_struct(@alias,"Alias")
  end
end

if __FILE__ == $0
  begin
    db=ObjDb.new(ARGV.shift,ARGV.shift)
  rescue SelectID
    abort ("USAGE: #{$0} [id] [cls]\n#{$!}")
  end
  puts db
end
