#!/usr/bin/ruby
require "libverbose"
require "libdb"

class ObjDb < Db
  def initialize(obj)
    super("odb",obj)
    self['id']=obj
    self[:alias]={}
    @doc.domain('command').each('alias'){|e0|
      e0.attr2db(self[:alias])
    }
    @doc.domain('status').each('title'){|e0|
      e0.attr2db(self[:status],'ref')
    }
  rescue SelectID
    abort ("USAGE: #{$0} [obj] [cls]\n#{$!}") if __FILE__ == $0
  end
end

if __FILE__ == $0
  obj,cls=ARGV
  odb=ObjDb.new(obj)
  if cls
    require "libclsdb"
    db=ClsDb.new(cls)
    odb.cover(db)
  end
  puts odb
end
