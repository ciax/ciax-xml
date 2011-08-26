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
  obj,app=ARGV
  begin
    odb=ObjDb.new(obj)
  rescue SelectID
    abort ("USAGE: #{$0} [obj] [app]\n#{$!}")
  end
  if app
    require "libappdb"
    odb >> AppDb.new(app)
  end
  puts odb
end
