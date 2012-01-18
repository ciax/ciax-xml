#!/usr/bin/ruby
require "librerange"
require "libdb"

# gid = Table Group ID
class SymDb < Db
  def initialize(gid=nil)
    super("sdb")
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
    sdb=ARGV.inject(Db.new('sdb')){|h,k|
      h.update(SymDb.new(k))
    }
    sdb=SymDb.new if sdb.empty?
  rescue SelectID
    warn "USAGE: #{$0} [id] ..."
    Msg.exit
  end
  puts sdb.path
end
