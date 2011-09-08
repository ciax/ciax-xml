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

  def cover_app # overwrite AppDb
    require "libappdb"
    app=AppDb.new(self['app_type'])
    if cmd=self[:command]
      app[:command].delete(:label)
      st=app[:structure][:command]
      self[:command][:alias].each{|k,v|
        st[k]=st.delete(v)
      }
      cmd.delete(:alias)
    end
    replace(rec_merge(app,self))
    @v.add("== Command List ==").add(self[:command][:label])
    self
  end

  def list
    @v
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
    odb.cover_app
  end
  puts Verbose.view_struct(odb)
  puts odb.list
end
