#!/usr/bin/ruby
require 'libdb'

# id = Table Group ID
module CIAX
  # Hex module
  module Hex
    # Hex DB
    class Db < Db
      def initialize
        super('hdb')
      end

      private

      def doc_to_db(doc)
        db = super
        hdb = db[:hexpack] = Hashx.new
        _rec_db(doc[:top], hdb) # top is 'hexpack'
        db
      end

      def _rec_db(doc, db)
        doc.each do |e1| # top is 'hexpack'
          item = Hashx.new(e1.to_h)
          case e1.name
          when 'pack'
            db.get(:packs) { [] } << item
            _rec_db(e1, item)
          when 'field'
            db.get(:fields) { [] } << item
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
