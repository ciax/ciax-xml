#!/usr/bin/ruby
require 'libdb'
require 'librerange'

# id = Table Group ID
module CIAX
  # Symbol module
  module Sym
    # Symbole DB
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
        db = super
        doc[:top].each do|e1|
          id = e1[:id]
          label = e1[:label]
          e1.each do|e2| # case
            (db[id] ||= []) << e2.to_h.update(type: e2.name)
          end
          verbose { "Symbol Table:#{id} : #{label}" }
        end
        db
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new.parse('r')
      begin
        dbi = Db.new.get(ARGV.shift)
      rescue InvalidID
        opt.usage('[id] (key) ..')
      end
      puts opt[:r] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
