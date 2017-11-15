#!/usr/bin/ruby
require 'libfrmdb'

module CIAX
  # Device Layer
  module Dev
    # Device DB
    class Db < Db
      def initialize
        super('ddb')
        @fdb = Frm::Db.new
      end

      # Compatible for Idb
      def run_list
        []
      end

      private

      def _doc_to_db(doc)
        at = doc[:attr]
        dbi = @fdb.get(at[:frm_id]).deep_copy
        dbi.update(at)
        __rec_db(doc[:top], dbi)
        dbi[:site_id] = dbi[:id]
        dbi
      end

      # doc => /site/field/assign
      def __rec_db(doc, dbi)
        doc.each do |e|
          if e[:id] # site or assign
            e.attr2item(dbi)
          else # field
            id = e.name.to_sym
            __rec_db(e, dbi[id])
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
