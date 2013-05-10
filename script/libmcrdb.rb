#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

module Mcr
  class Db < Db
    def initialize
      super('mdb')
    end

    def set(id=nil)
      super{|doc|
        hash={}
        hash.update(doc)
        mdb=(hash[:command]||={})
        doc.top.each{|e0|
          id=e0.attr2db(mdb)
          verbose{"MACRO:[#{id}]"}
          select=((mdb[:select]||={})[id]||=[])
          final={}
          e0.each{|e1,rep|
            attr=e1.to_h
            set_par(e1,id,mdb) && next
            attr['type'] = e1.name
            case e1.name
            when 'check','wait'
              select << mkcond(e1,attr)
            when 'goal'
              select << mkcond(e1,attr)
              final.update(attr)['type'] = 'check'
            when 'exec'
              attr['cmd']=getcmd(e1)
              attr.delete('name')
              select << attr
              verbose{"COMMAND:[#{e1['name']}]"}
            when 'mcr'
              cmd=attr['cmd']=getcmd(e1)
              attr['label']=mdb[:label][cmd.first]
              attr.delete('name')
              select << attr
            end
          }
          select << final unless final.empty?
        }
        hash
      }
    end

    private
    def mkcond(e1,attr)
      e1.each{|e2|
        (attr['stat']||=[]) << e2.to_h
      }
      attr
    end

    def getcmd(e1)
      cmd=[e1['name']]
      e1.each{|e2|
        cmd << e2.text
      }
      cmd
    end
  end
end

if __FILE__ == $0
  begin
    mdb=Mcr::Db.new.set(ARGV.shift)
  rescue InvalidID
    Msg.usage "[id] (key) .."
    Msg.exit
  end
  puts mdb.path(ARGV)
end

