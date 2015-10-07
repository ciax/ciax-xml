#!/usr/bin/ruby
require 'libdb'
require 'librerange'

# id = Table Group ID
module CIAX
  module Sym
    class Db < Db
      def initialize
        super('sdb')
      end

      def self.pack(ary = [])
        sdb = Sym::Db.new
        dbi = Dbi.new
        ary.compact.each { |k| dbi.update(sdb.get(k)) }
        dbi
      end

      private
      def doc_to_db(doc)
        db = Dbi.new
        doc[:top].each{|e1|
          id = e1['id'].to_sym
          label = e1['label']
          e1.each{|e2| # case
            (db[id] ||= []) << e2.to_h.update({ 'type' => e2.name })
          }
          verbose { "Symbol Table:#{id} : #{label}" }
        }
        db
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    begin
      sdb = Sym::Db.new.get(ARGV.shift)
    rescue InvalidID
      Msg.usage '[id] ...'
    end
    puts sdb.path(ARGV)
  end
end
