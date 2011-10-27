#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class McrDb < Db
  def initialize(mcr,nocache=nil)
    super('mdb')
    cache(mcr,nocache){|doc|
      update(doc)
      doc.top.each{|e0|
        id=e0.attr2db(self)
        @v.msg{"MACRO:[#{id}]"}
        select=((self[:select]||={})[id]||=[])
        e0.each{|e1,rep|
          attr=e1.to_h
          attr['type'] = e1.name
          case e1.name
          when 'par'
            ((self[:parameter]||={})[id]||=[]) << e1.text
          when 'break','check','wait'
            join=e1['join']||'all'
            e1.each{|e2|
              (attr[join]||=[]) << e2.to_h
            }
            select << attr
          when 'mcr','exec'
            attr['cmd']=getcmd(e1)
            attr.delete('name')
            select << attr
            @v.msg{"COMMAND:[#{e1['name']}]"}
          end
        }
      }
    }
  end

  private
  def getcmd(e1)
    cmd=[e1['name']]
    e1.each{|e2|
      cmd << e2.text
    }
    cmd
  end

end

if __FILE__ == $0
  begin
    mdb=McrDb.new(ARGV.shift,true)
  rescue SelectID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts mdb.path(ARGV)
end

