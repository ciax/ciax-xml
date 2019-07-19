#!/usr/bin/env ruby
require 'libfrmdb'
require 'libinsdb'

module CIAX
  # Device Layer
  module Dev
    # Device DB
    class Db < Dbx::Index
      def initialize(idb = nil)
        super('ddb')
        @fdb = Frm::Db.new
        return unless idb
        @host_ddb = idb.host_ddb
        reduce(@host_ddb.keys)
      end

      private

      def _doc_to_db(doc)
        at = doc[:attr]
        dbi = @fdb.get(at[:frm_id]).deep_copy
        dbi.update(at)
        __rec_db(doc[:top], dbi)
        id = dbi[:site_id] = dbi[:id]
        dbi[:host] = @host_ddb[id] if @host_ddb
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
      Opt::Get.new('[id] (key) ..', options: 'r') do |opt, args|
        db = Db.new(Ins::Db.new)
        puts "Dev list = #{db.list.inspect}"
        dbi = db.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
