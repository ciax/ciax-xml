#!/usr/bin/ruby
require 'libappdb'
require 'libinscmddb'

module CIAX
  # Instance Layer
  module Ins
    # Instance DB
    class Db < DbTree
      include Wat::Db
      attr_reader :proj, :run_list
      def initialize(proj = nil)
        @proj = proj || ENV['PROJ'] || 'all'
        super('idb')
        @adb = App::Db.new
        @cdb = CmdDb.new
        ___init_lists
      end

      def valid_apps(applist)
        @displist.valid_keys.select! do |id|
          applist.include?(get(id)[:app_id])
        end
      end

      def valid_devs
        @displist.valid_keys.each_with_object({}) do |s, hash|
          hash[get(s)[:frm_site]] = @run_list.include?(s)
        end
      end

      private

      def ___init_lists
        sites = @displist.valid_keys
        @run_list = sites.select do |id|
          atrb = get(id) || @docs.get(id)[:attr]
          host = atrb[:host]
          atrb[:run] != 'false' && (host == 'localhost' || host == HOST)
        end
      end

      # doc is <project>
      # return //project/group/instance
      def _doc_to_db(doc)
        at = doc[:attr]
        aid = at[:app_id]
        # Need deep copy to avoid mixing up different object
        # which shares same adb item
        adbi = @adb.ref(aid) || super
        dbi = adbi.deep_copy.update(at)
        ___init_general(dbi)
        _init_command_db(dbi, doc)
        ___init_status_db(doc, dbi)
        _init_watch(doc, dbi)
        dbi
      end

      def _get_displist
        super(@proj)
      end

      def _new_docs
        Xml::Doc.new(@type, @proj)
      end

      # Command Domain
      def _init_command_db(dbi, doc)
        return unless doc.key?(:command)
        cdb = super(dbi)
        @cdb.override(doc[:command][:ref], cdb)
        cdb
      end

      # Status Domain
      def ___init_status_db(doc, dbi)
        sdb = dbi.get(:status) { Hashx.new }
        grp = sdb.get(:group) { Hashx.new }
        idx = sdb.get(:index) { Hashx.new }
        doc.get(:status) { [] }.each do |e0|
          ___get_skeleton(e0, sdb, grp, idx)
        end
        sdb
      end

      def ___init_general(dbi)
        dbi[:proj] = @proj
        dbi[:site_id] = dbi[:ins_id] = dbi[:id]
        dbi.get(:frm_site) { dbi[:id] }
      end

      def ___get_skeleton(e0, sdb, grp, idx)
        key = e0.name.to_sym
        db = sdb.get(key) { Hashx.new }
        if key == :symtbl
          sdb[:symtbl] << e0['ref']
        else
          ___init_grp(e0, db, grp, idx)
        end
      end

      def ___init_grp(e0, db, grp, idx)
        e0.attr2item(db, :ref)
        e0.each do |e1|
          e1.attr2item(idx)
          ag = grp[e0[:ref]]
          ___pos_grp(ag.get(:members) { [] }, e1['ref'], e1['id'])
        end
      end

      # add alias to group in position (just after the referenced item)
      #  this feature is required by indexed status
      #  ex. add [c1,c2] to [a1,b1, a2,b2] => [a1,b1,c1, a2,b2,c2]
      def ___pos_grp(ary, ref, id)
        if (i = ary.rindex(ref))
          ary.insert(i + 1, id)
        else
          ary << id
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', options: 'r') do |opt, args|
        db = Db.new
        puts "Run list = #{db.run_list.inspect}"
        puts "Dev list = #{db.valid_devs.inspect}"
        dbi = db.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
