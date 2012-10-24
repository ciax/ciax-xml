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
          p=(hash[:command]||={})
          g=(p[:group]||={})
          key=e0.add_item(g)
          item=(g[key][:list]||=[])
          e0.each{|e1|
            item << e1['id']
            e1.attr2db(p)
          }
        }
        doc.domain('status').each{|e0|
          p=(hash[:status]||={})
          if e0.name == 'group'
            e0.add_item(p[:group]||={},'ref')
          else
            e0.attr2db(p,'ref')
          end
        }
        hash
      }
    end

    # overwrite App::Db
    def cover_app
      require "libappdb"
      cover(App::Db.new(self['app_type']))
    end
  end
end

if __FILE__ == $0
  begin
    Msg.getopts("a",{"a"=>"app mode"})
    id=ARGV.shift
    db=Ins::Db.new(id)
  rescue InvalidID
    Msg.usage("(opt) [id] (key) ..",*$optlist)
    Msg.exit
  end
  db=db.cover_app if $opt["a"]
  puts db.path(ARGV)
end
