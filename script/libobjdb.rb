#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libclsdb"

class ObjDb < ClsDb
  def initialize(obj,cls=nil) # cls can be gotten from odb, otherwise DB-object
    if cls
      super(cls)
      self['class']=cls
    else
      self[:command]={}
      self[:status]={}
    end
    self['id']=obj
    self[:alias]={}
    doc=XmlDoc.new('odb',obj)
    update(doc)
    doc.domain('command').each('alias'){|e0|
      e0.attr2db(self[:alias])
    }
    self[:status][:label]||={}
    doc.domain('status').each('title'){|e0|
      e0.attr2db(self[:status],'ref')
    }
  rescue SelectID
    abort ("USAGE: #{$0} [id] [cls]\n#{$!}") if __FILE__ == $0
  end
end

if __FILE__ == $0
  puts ObjDb.new(ARGV.shift,ARGV.shift)
end
