#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libmodcache"
class McrDb < Hash
  include ModCache
  def initialize(mcr,nocache=nil)
    @v=Msg::Ver.new('mdb',5)
    cache('mdb',mcr,nocache){|doc|
      hash=Hash[doc]
      init_command(doc.top,hash)
      hash
    }
  end

  private
  def init_command(mdb,hash)
    mdb.each{|e0|
      id=e0.attr2db(hash)
      e0.each{|e1,rep|
        case e1.name
        when 'par'
          ((hash[:parameter]||={})[id]||=[]) << e1.text
        when 'break','check'
          stat={:type => e1.name,:cond => []}
          e1.each{|e2|
            attr=e2.to_h
            attr['val'] = e2.text
            stat[:cond] << attr.freeze
          }
          ((hash[:sequence]||={})[id]||=[]) << stat
        when 'exec'
          ((hash[:sequence]||={})[id]||=[]) << e1.text
          @v.msg{"COMMAND:[#{id}] #{e1.text}"}
        end
      }
    }
    self
  end
end

if __FILE__ == $0
  begin
    adb=McrDb.new(ARGV.shift,true)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts adb
end

