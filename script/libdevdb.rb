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

      private

      def doc_to_db(doc)
        at = doc[:attr]
        dbi = @fdb.get(at[:frm_id]).deep_copy
        dbi.update(at)
        rec_db(doc[:top], dbi)
        dbi[:site_id] = dbi[:id]
        dbi
      end

      # doc => /site/field/assign
      def rec_db(doc, dbi)
        doc.each do |e|
          if e[:id] # site or assign
            e.attr2item(dbi)
          else # field
            id = e.name.to_sym
            rec_db(e, dbi[id])
          end
        end
      end

      def _site_list(prj, gr)
        prj[:site].each do |k, v|
          gr.put_item(k, v[:label])
        end
        gr
      end

      # Compatible for Idb
      def run_list
        []
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
