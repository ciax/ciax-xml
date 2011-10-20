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
        select=((self[:select]||={})[id]||=[])
        e0.each{|e1,rep|
          case e1.name
          when 'par'
            ((self[:parameter]||={})[id]||=[]) << e1.text
          when 'break','check'
            stat=e1.to_h
            stat['type'] = e1.name
            e1.each{|e2|
              (stat['cond']||=[]) << e2.to_h
            }
            select << stat
          when 'exec'
            cmd=[e1['name']]
            e1.each{|e2|
              cmd << e2.text
            }
            select << {'ins' => e1['ins'], 'cmd' => cmd}
            @v.msg{"COMMAND:[#{id}] #{e1.text}"}
          end
        }
      }
    }
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

