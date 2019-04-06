#!/usr/bin/env ruby
require 'libdb'
require 'librerange'

# id = Table Group ID
module CIAX
  # Symbol module
  module Sym
    # Symbole DB
    class Db < Db::Index
      def initialize
        super('sdb')
      end

      def get_dbi(ary = [])
        dbi = CIAX::Db::Item.new
        ary.compact.each { |k| dbi.update(get(k)) }
        dbi
      end

      private

      def _doc_to_db(doc)
        db = super
        doc[:top].each do |e1|
          id = e1[:id]
          label = e1[:label]
          e1.each do |e2| # case
            db.get(id) { [] } << e2.to_h.update(type: e2.name)
          end
          verbose { "Symbol Table:#{id} : #{label}" }
        end
        db
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
