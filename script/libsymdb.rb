#!/usr/bin/ruby
require "librerange"
require "libdb"

# id = Table Group ID
module Sym
  class Db < Db
    extend Msg::Ver
    def initialize(id)
      Db.init_ver('SymDb')
      super("sdb",id){|doc|
        hash={}
        doc.top.each{|e1|
          id=e1['id'].to_sym
          label=e1['label']
          e1.each{|e2| # case
            (hash[id]||=[]) << e2.to_h.update({'type' => e2.name})
          }
          Db.msg{"Symbol Table:#{id} : #{label}"}
        }
        hash
      }
    rescue InvalidDEV
      raise $! if __FILE__ == $0
    end

    def self.pack(ary=[])
      sdb=Sym::Db.new(ary.shift).dup
      ary.each{|k| sdb.update(Sym::Db.new(k)) }
      sdb
    end
  end
end

if __FILE__ == $0
  begin
    sdb=Sym::Db.new(ARGV.shift)
  rescue InvalidDEV
    Msg.usage "[id] ..."
    Msg.exit
  end
  puts sdb.path(ARGV)
end
