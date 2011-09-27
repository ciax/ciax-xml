#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libmodcache"
class McrDb < Hash
  include ModCache
  def initialize(mcr,nocache=nil)
    @v=Msg::Ver.new('mdb',5)
    cache('mdb',mcr,nocache){|doc|
      update(doc)
      doc.top.each{|e0|
        id=e0.attr2db(self)
        e0.each{|e1,rep|
          case e1.name
          when 'par'
            ((self[:parameter]||={})[id]||=[]) << e1.text
          when 'break','check'
            stat={:type => e1.name,:cond => []}
            e1.each{|e2|
              stat[:cond] << e2.to_h
            }
            ((self[:sequence]||={})[id]||=[]) << stat
          when 'exec'
            ((self[:sequence]||={})[id]||=[]) << e1.text
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
  puts mdb.select(ARGV)
end

