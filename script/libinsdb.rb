#!/usr/bin/ruby
require "libdb"

module Ins
  class Db < Db
    def initialize(id)
      self['id']=id
      super('idb',id){|doc|
        hash={}
        hash.update(doc)
        doc.domain('init').each{|e0|
          ((hash[:rspframe]||={})[:assign]||={})[e0['id']]=e0.text
        }
        doc.domain('select').each{|e0|
          p=group(e0,hash[:command]||={})
          e0.attr2db(p)
        }
        doc.domain('status').each{|e0|
          p=group(e0,hash[:status]||={})
          e0.attr2db(p,'ref')
        }
        hash
      }
    end

    # overwrite App::Db
    def cover_app
      require "libappdb"
      cover(App::Db.new(self['app_type']))
    end

    private
    def group(e,p)
      case e.name
      when 'group'
        p=(p[:group]||={})
      end
      p
    end
  end
end

if __FILE__ == $0
  require "optparse"
  begin
    opt=ARGV.getopts("af")
    id=ARGV.shift
    db=Ins::Db.new(id)
  rescue
    Msg.usage("(-af) [id] (key) ..","-a:make adb","-f:make fdb")
    Msg.exit
  end
  db=db.cover_app if opt["a"]
  db=db.cover_app.cover_frm if opt["f"]
  puts db.path(ARGV)
end
