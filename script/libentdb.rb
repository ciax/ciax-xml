#!/usr/bin/ruby
require "libmsg"
require "libmodcache"

class EntDb < Hash
  include ModCache
  def initialize(id,nocache=nil)
    @v=Msg::Ver.new('edb',5)
    self['id']=id
    cache('edb',id,nocache){|doc|
      update(doc)
      doc.domain('init').each{|e0|
        (self[:field]||={})[e0['id']]=e0.text
      }
      doc.domain('select').each{|e0|
        e0.attr2db(self[:command]||={})
      }
      doc.domain('status').each{|e0|
        e0.attr2db(self[:status]||={},'ref')
      }
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
  id=ARGV.shift
  begin
    edb=EntDb.new(id,true)
  rescue SelectID
    warn "USAGE: #{$0} [id] (-) (key) .."
    Msg.exit
  end
  edb.cover_app(true) if ARGV.shift
  puts edb.select(ARGV)
end
