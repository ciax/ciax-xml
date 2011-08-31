#!/usr/bin/ruby
require "libverbose"
require "libdbcache"

class ObjDb < DbCache
  def initialize(obj)
    super("odb",obj)
    self['id']=obj
  end

  def refresh
    update(doc)
    doc.domain('init').each('field'){|e0|
      self[:field]||={}
      self[:field][e0['id']]=e0.text
    }
    doc.domain('command').each('alias'){|e0|
      e0.attr2db(self[:alias]||={})
    }
    doc.domain('status').each('title'){|e0|
      e0.attr2db(self[:status]||={},'ref')
    }
    save
  end
end

if __FILE__ == $0
  obj,app=ARGV
  begin
    odb=ObjDb.new(obj).refresh
  rescue SelectID
    abort ("USAGE: #{$0} [obj] (-)\n#{$!}")
  end
  if app
    require "libappdb"
    odb >> AppDb.new(odb['app_type'])
  end
  puts odb
end
