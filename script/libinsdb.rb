#!/usr/bin/ruby
require "libdb"

class InsDb < Db
  def initialize(id,nocache=nil)
    super('idb')
    self['id']=id
    cache(id,nocache){|doc|
      update(doc)
      doc.domain('init').each{|e0|
        ((self[:rspframe]||={})[:assign]||={})[e0['id']]=e0.text
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
      st=app[:command][:select]
      cmd[:alias].each{|k,v|
        st[k]=st.delete(v)
      }
      cmd.delete(:alias)
    end
    app.deep_update(self)
  end
end

if __FILE__ == $0
  require "optparse"
  begin
    opt=ARGV.getopts("af")
    id=ARGV.shift
    db=InsDb.new(id,true)
  rescue
    warn "USAGE: #{$0} (-af) [id] (key) .."
    Msg.exit
  end
  db=db.cover_app(true) if opt["a"]
  db=db.cover_app(true).cover_frm(true) if opt["f"]
  puts db.path(ARGV)
end
