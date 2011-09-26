#!/usr/bin/ruby
require "libmsg"
require "libmodcache"
require "librerange"

class SymDb < Hash
  include ModCache
  def initialize(nocache=nil)
    @v=Msg::Ver.new("Symbol",6)
    @nocache=nocache
  end

  def add(gid=nil) # gid = Table Group ID
    cache('sdb',gid,@nocache){|doc|
      doc.top.each{|e1|
        id=e1['id']
        label=e1['label']
        e1.each{|e2| # case
          (self[id]||=[]) << e2.to_h.update({'type' => e1['type']})
        }
        @v.msg{"Symbol Table:#{id} : #{label}"}
      }
    }
    self
  rescue SelectID
    raise $! if __FILE__ == $0
  end

  def convert(view,tid=nil)
    @tid=tid||@tid
    vs=view['symbol']||={}
    view['stat'].each{|key,val|
      next if val == ''
      tbl=table(sid=@tid[key]) || next
      @v.msg{"ID=#{key},table=#{sid}"}
      tbl.each{|hash|
        case hash['type']
        when 'range'
          next unless ReRange.new(hash['val']) == val
          @v.msg{"VIEW:Range:[#{hash['val']}] and [#{val}]"}
          vs[key]={'type' => 'num'}.update(hash)
        when 'regexp','string'
          next unless /#{hash['val']}/ === val || val == 'default'
          @v.msg{"VIEW:Regexp:[#{hash['val']}] and [#{val}]"}
          vs[key]={'type' => 'str'}.update(hash)
        end
        break
      }
    }
    self
  end

  private
  def table(id)
    if id && key?(id)
      tbl=(self[id]||=[])
      tbl << {'class' => 'alarm','msg' => 'N/A','val' => 'default'}
    else
      Msg.warn("Table[#{id}] not exist") if id
      false
    end
  end
end

if __FILE__ == $0
  begin
    sdb=SymDb.new(true)
    ARGV.each{|id|
      sdb.add(id)
    }.empty? && sdb.add
  rescue SelectID
    warn "USAGE: #{$0} [id] ..."
    Msg.exit
  end
  puts sdb
end
