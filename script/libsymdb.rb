#!/usr/bin/ruby
require "librerange"
require "libdb"

# gid = Table Group ID
class SymDb < Db
  def initialize(gid=nil)
    super("sdb")
    set(gid){|doc|
      hash={}
      doc.top.each{|e1|
        id=e1['id']
        label=e1['label']
        e1.each{|e2| # case
          (hash[id]||=[]) << e2.to_h.update({'type' => e2.name})
        }
        @v.msg{"Symbol Table:#{id} : #{label}"}
      }
      hash
    }
  rescue SelectID
    raise $! if __FILE__ == $0
  end

  def self.pack(ary=[])
    sdb=Db.new('sdb')
    ary.each{|k|
      sdb.update(new(k))
    }.empty? && new
    sdb
  end
end

if __FILE__ == $0
  begin
    sdb=SymDb.pack(ARGV)
  rescue SelectID
    warn "USAGE: #{$0} [id] ..."
    Msg.exit
  end
  puts sdb.path
end
