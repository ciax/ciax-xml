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

      def set(id=nil)
        super
      rescue InvalidID
        # No error even if no sdb associated with ins/app id
        raise $! if __FILE__ == $0
      end

      def self.pack(ary=[])
        sdb=Sym::Db.new
        ary.each{|k| sdb.set(k) }
        sdb
      end

      private
      def doc_to_db(doc)
        hash={}
        doc.top.each{|e1|
          id=e1['id'].to_sym
          label=e1['label']
          e1.each{|e2| # case
            (hash[id]||=[]) << e2.to_h.update({'type' => e2.name})
          }
          verbose("SymDb","Symbol Table:#{id} : #{label}")
        }
        hash
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
