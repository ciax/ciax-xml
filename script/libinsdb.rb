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
          p = sdb.get(e0.name.to_sym) { Hashx.new }
          case e0.name
          when 'symtbl'
            sdb[:symtbl] << e0['ref']
          else # group, index
            e0.attr2item(p, :ref)
            e0.each do |e1|
              e1.attr2item(idx)
              ag = grp[e0[:ref]]
              ag.get(:members) { [] } << e1['id']
            end
          end
        end
        sdb
      end

      def init_general(dbi)
        dbi[:proj] = ENV['PROJ']
        dbi[:site_id] = dbi[:ins_id] = dbi[:id]
        dbi.get(:frm_site) { dbi[:id] }
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
