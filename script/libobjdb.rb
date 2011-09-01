#!/usr/bin/ruby
require "libverbose"
require "libdb"
require "libcache"

class ObjDb < Db
  def initialize(obj,nocache=nil)
    @v=Verbose.new('odb',5)
    self['id']=obj
    update(Cache.new('odb',obj,nocache){|doc|
             hash=Hash[doc]
             doc.domain('init').each{|e0|
               hash[:field]||={}
               hash[:field][e0['id']]=e0.text
             }
             doc.domain('command').each{|e0|
               e0.attr2db(hash[:alias]||={})
             }
             doc.domain('status').each{|e0|
               e0.attr2db(hash[:status]||={},'ref')
             }
             hash
           })
  end
end

if __FILE__ == $0
  obj,app=ARGV
  begin
    odb=ObjDb.new(obj,true)
  rescue SelectID
    abort ("USAGE: #{$0} [obj] (-)\n#{$!}")
  end
  if app
    require "libappdb"
    odb >> AppDb.new(odb['app_type'])
  end
  puts odb
end
