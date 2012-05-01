#!/usr/bin/ruby
require "libdb"

class InsDb < Db
  def initialize(id)
    super('idb')
    self['id']=id
    cache(id){|doc|
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

  # overwrite App::Db
  def cover_app
    require "libappdb"
    cover(App::Db.new(self['app_type']))
  end
end

if __FILE__ == $0
  require "optparse"
  begin
    opt=ARGV.getopts("af")
    id=ARGV.shift
    db=InsDb.new(id)
  rescue
    Msg.usage("(-af) [id] (key) ..","-a:make adb","-f:make fdb")
    Msg.exit
  end
  db=db.cover_app if opt["a"]
  db=db.cover_app.cover_frm if opt["f"]
  puts db.path(ARGV)
end
