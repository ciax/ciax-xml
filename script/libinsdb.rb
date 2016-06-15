#!/usr/bin/ruby
require 'libappdb'
require 'libcmddb'

module CIAX
  # Instance Layer
  module Ins
    # Instance DB
    class Db < DbCmd
      include Wat::Db
      attr_reader :proj, :run_list
      def initialize(proj = nil)
        @proj = proj || ENV['PROJ'] || 'all'
        super('idb', @proj)
        @adb = App::Db.new
        @cdb = Cmd::Db.new
        @run_list = @displist.valid_keys.select do |id|
          host = (_get_cache(id) || @docs.get(id)[:attr])[:host]
          host == 'localhost' || host == HOST
        end
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
          _pos_grp(ag.get(:members) { [] }, e1['ref'], e1['id'])
        end
      end

      # add alias to group in position (just after the referenced item)
      #  this feature is required by indexed status
      #  ex. add [c1,c2] to [a1,b1, a2,b2] => [a1,b1,c1, a2,b2,c2]
      def _pos_grp(ary, ref, id)
        if (i = ary.rindex(ref))
          ary.insert(i + 1, id)
        else
          ary << id
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', 'r') do |opt, args|
        db = Db.new
        puts "Run list = #{db.run_list.inspect}"
        dbi = db.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
