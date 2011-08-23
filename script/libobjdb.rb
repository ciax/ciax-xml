#!/usr/bin/ruby
require "libverbose"
require "libdbcache"

class ObjDb < DbCache
  def initialize(obj)
    super("odb",obj)
    self['id']=obj
  end

  def refresh
    doc=super
    update(doc)
    doc.domain('command').each('alias'){|e0|
      e0.attr2db(self[:alias]||={})
    }
    doc.domain('status').each('title'){|e0|
      e0.attr2db(self[:status]||={},'ref')
    }
  end
end

if __FILE__ == $0
  obj,cls=ARGV
  begin
    odb=ObjDb.new(obj)
  rescue SelectID
    abort ("USAGE: #{$0} [obj] [cls]\n#{$!}")
  end
  if cls
    require "libclsdb"
    odb >> ClsDb.new(cls)
  end
  puts odb
end
