#!/usr/bin/ruby
require 'libfrmdb'

module CIAX
  # Device Layer
  module Dev
    # Device DB
    class Db < Db
      def initialize
        super('ddb')
      end

      def get(id = nil)
        dbi = super
        dbi.cover(Frm::Db.new.get(dbi[:frm_id]))
      end

      private

      def doc_to_db(doc)
        db = rec_db(doc[:top])
        db[:proj] = PROJ
        db[:site_id] = db[:id]
        db
      end

      def rec_db(e0, dbi = Dbi.new)
        (dbi ||= Dbi.new).update(e0.to_h)
        e0.each do|e|
          if e[:id]
            e.attr2item(dbi)
          else
            id = e.name.to_sym
            verbose { "Override [#{id}]" }
            rec_db(e, dbi[id] ||= {})
          end
        end
        dbi
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      begin
        dbi = Db.new.get(ARGV.shift)
      rescue InvalidID
        OPT.usage('[id] (key) ..')
      end
      puts OPT[:r] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
