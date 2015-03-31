#!/usr/bin/ruby
require "libdb"
require "librerange"

# id = Table Group ID
module CIAX
  module Sym
    class Db < Db
      def initialize
        super('sdb')
      end

      def add(id=nil)
        update(set(id))
      rescue InvalidID
        # No error even if no sdb associated with ins/app id
        raise $! if __FILE__ == $0
      end

      def self.pack(ary=[])
        sdb=Sym::Db.new
        ary.each{|k| sdb.add(k) }
        sdb
      end

      private
      def doc_to_db(doc)
        db=Dbi.new
        doc[:top].each{|e1|
          id=e1['id'].to_sym
          label=e1['label']
          e1.each{|e2| # case
            (db[id]||=[]) << e2.to_h.update({'type' => e2.name})
          }
          verbose("SymDb","Symbol Table:#{id} : #{label}")
        }
        db
      end
    end
  end

  if __FILE__ == $0
    begin
      sdb=Sym::Db.new.set(ARGV.shift)
    rescue InvalidID
      Msg.usage "[id] ..."
      Msg.exit
    end
    puts sdb.path(ARGV)
  end
end
