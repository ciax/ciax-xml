#!/usr/bin/ruby
require "libdb"

module Ins
  class Db < Db
    def initialize(id)
      self['id']=id
      super('idb',id,ENV['PROJ']){|doc|
        hash={}
        hash.update(doc)
        doc.domain('cmdlist').each{|e0|
          p=((hash[:app]||={})[:command]||={})
          g=(p[:group]||={})
          key=e0.add_item(g)
          item=(g[key][:list]||=[])
          e0.each{|e1|
            item << e1['id']
            e1.attr2db(p)
          }
        }
        doc.domain('status').each{|e0|
          p=((hash[:app]||={})[:status]||={})
          p=(p[:group]||={}) if e0.name == 'group'
          e0.attr2db(p,'ref')
        }
        hash
      }
    end

    # overwrite Loc::Db
    def cover_loc
      require "liblocdb"
      cover(Loc::Db.new(self['site'])).cover_app.cover_frm
    end
  end
end

if __FILE__ == $0
  begin
    Msg.getopts("l",{"l"=>"loc mode"})
    id=ARGV.shift
    db=Ins::Db.new(id)
  rescue InvalidID
    Msg.usage("(opt) [id] (key) ..",*$optlist)
    Msg.exit
  end
  db=db.cover_loc if $opt["l"]
  puts db.path(ARGV)
end
