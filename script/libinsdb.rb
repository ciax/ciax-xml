#!/usr/bin/ruby
require 'libappdb'
require 'libcmddb'

module CIAX
  # Instance Layer
  module Ins
    # Instance DB
    class Db < Db
      include Wat::Db
      def initialize
        super('idb')
        @adb = App::Db.new
        @cdb = Cmd::Db.new
      end

      private

      # doc is <project>
      # return //project/group/instance
      def doc_to_db(doc)
        at = doc[:attr]
        dbi = @adb.get(at[:app_id]).deep_copy
        dbi.update(at)
        init_general(dbi)
        init_command(doc, dbi)
        init_status(doc, dbi)
        init_watch(doc, dbi)
        dbi
      end

      # Command Domain
      def init_command(doc, dbi)
        return self unless doc.key?(:command)
        cdb = super(dbi)
        @cdb.cover(doc[:command][:ref], cdb)
        cdb
      end

      # Status Domain
      def init_status(doc, dbi)
        sdb = dbi.get(:status) { Hashx.new }
        grp = sdb.get(:group) { Hashx.new }
        idx = sdb.get(:index) { Hashx.new }
        doc.get(:status) { [] }.each do|e0|
          _get_skeleton(e0, sdb, grp, idx)
        end
        sdb
      end

      def init_general(dbi)
        dbi[:proj] = ENV['PROJ']
        dbi[:site_id] = dbi[:ins_id] = dbi[:id]
        dbi.get(:frm_site) { dbi[:id] }
      end

      private

      def _get_skeleton(e0, sdb, grp, idx)
        key = e0.name.to_sym
        db = sdb.get(key) { Hashx.new }
        if key == :symtbl
          sdb[:symtbl] << e0['ref']
        else
          _init_grp(e0, db, grp, idx)
        end
      end

      def _init_grp(e0, db, grp, idx)
        e0.attr2item(db, :ref)
        e0.each do |e1|
          e1.attr2item(idx)
          ag = grp[e0[:ref]]
          ag.get(:members) { [] } << e1['id']
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
