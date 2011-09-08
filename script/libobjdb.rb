#!/usr/bin/ruby
require "libverbose"
require "libcache"

class ObjDb < Hash
  def initialize(obj,nocache=nil)
    @v=Verbose.new('odb',5)
    self['id']=obj
    odb=Cache.new('odb',obj,nocache){|doc|
      hash=Hash[doc]
      doc.domain('init').each{|e0|
        hash[:field]||={}
        hash[:field][e0['id']]=e0.text
      }
      doc.domain('select').each{|e0|
        e0.attr2db(hash[:command]||={})
      }
      doc.domain('status').each{|e0|
        e0.attr2db(hash[:status]||={},'ref')
      }
      hash
    }
    update(odb)
  end

  def >>(hash) # overwrite hash
    if self[:command] && al=self[:command][:label]
      hash[:command].delete(:label)
    end
    replace(rec_merge(hash,self))
  end

  private
  def rec_merge(i,o)
    i.merge(o){|k,a,b|
      Hash === b ? rec_merge(a,b) : b
    }
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
  puts Verbose.view_struct(odb)
end
