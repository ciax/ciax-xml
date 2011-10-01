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
    replace(rec_merge(app,self))
    self
  end

  def cover_frm(nocache=nil)
    require "libfrmdb"
    frm=FrmDb.new(self['frm_type'],nocache)
    replace(rec_merge(frm,self))
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
  require "optparse"
  begin
    opt=ARGV.getopts("af")
    id=ARGV.shift
    idb=InsDb.new(id,true)
  rescue
    warn "USAGE: #{$0} (-af) [id] (key) .."
    Msg.exit
  end
  idb.cover_app(true) if opt["a"]
  idb.cover_frm(true) if opt["f"]
  puts idb.path(ARGV)
end
