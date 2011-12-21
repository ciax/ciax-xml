#!/usr/bin/ruby
require "librerange"
require "libdb"

class SymDb < Db
  def initialize
    super("sdb")
  end

  def add(gid=nil) # gid = Table Group ID
    cache(gid){|doc|
      doc.top.each{|e1|
        id=e1['id']
        label=e1['label']
        e1.each{|e2| # case
          (self[id]||=[]) << e2.to_h.update({'type' => e2.name})
        }
        @v.msg{"Symbol Table:#{id} : #{label}"}
      }
    }
    self
  rescue SelectID
    raise $! if __FILE__ == $0
    self
  end
end

if __FILE__ == $0
  begin
    sdb=SymDb.new
    ARGV.each{|id|
      sdb.add(id)
    }.empty? && sdb.add
  rescue SelectID
    warn "USAGE: #{$0} [id] ..."
    Msg.exit
  end
  puts sdb
end
