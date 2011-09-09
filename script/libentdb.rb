#!/usr/bin/ruby
require "libmsg"
require "libcache"

class EntDb < Hash
  include Cache
  def initialize(id,nocache=nil)
    @v=Msg::Ver.new('edb',5)
    self['id']=id
    cache('odb',id,nocache){|doc|
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
  end

  def cover_app(nocache=nil) # overwrite AppDb
    require "libappdb"
    app=AppDb.new(self['app_type'],nocache)
    if cmd=self[:command]
      app[:command].delete(:label)
      st=app[:command][:structure]
      cmd[:alias].each{|k,v|
        st[k]=st.delete(v)
      }
      cmd.delete(:alias)
    end
    replace(rec_merge(app,self))
    mklist
    self
  end

  private
  def rec_merge(i,o)
    i.merge(o){|k,a,b|
      Hash === b ? rec_merge(a,b) : b
    }
  end
end

if __FILE__ == $0
  id,app=ARGV
  begin
    edb=EntDb.new(id,true)
  rescue SelectID
    abort ("USAGE: #{$0} [id] (-)\n#{$!}")
  end
  if app
    edb.cover_app(true)
  end
  puts Msg.view_struct(edb)
end
