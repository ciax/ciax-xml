#!/usr/bin/ruby
require 'libappdb'

module CIAX
  # Instance Layer
  module Ins
    # Instance DB
    class Db < Db
      include Wat::Db
      def initialize
        super('idb')
        @adb = App::Db.new
      end

      private

      # doc is <project>
      # return //project/group/instance
      def doc_to_db(doc)
        at = doc[:attr]
        dbi = @adb.get(at[:app_id])
        dbi.update(at)
        init_general(dbi)
        init_command(doc, dbi)
        init_status(doc, dbi)
        init_watch(doc, dbi)
        dbi
      end

      # Command Domain
      def init_command(doc, dbi)
        return self unless doc.key?(:alias)
        cdb = dbi[:command]
        @idx = cdb[:index]
        @grps = cdb[:group]
        @units = cdb[:unit]
        cdb[:group]['gal'] = Hashx.new(caption: 'Alias')
        _add_unit(doc[:alias], 'gal')
        cdb
      end

      def _add_item(e0, gid)
        id, itm = super
        ref = itm.delete(:ref)
        itm.update(@idx[ref].pick([:parameters, :body]))
        e0.each do|e1|
          (itm[:argv] ||= []) << e1.text
        end
        [id, itm]
      end

      # Status Domain
      def init_status(doc, dbi)
        sdb = (dbi[:status] ||= {})
        grp = (sdb[:group] ||= {})
        (doc[:status] || []).each do|e0|
          p = (sdb[e0.name.to_sym] ||= {})
          case e0.name
          when 'alias'
            e0.attr2item(p)
            ag = (grp[:alias] ||= { caption: 'Alias', members: [] })
            ag[:members] << e0['id']
          when 'symtbl'
            sdb[:symtbl] << e0['ref']
          else # group, index
            e0.attr2item(p, :ref)
          end
        end
        sdb
      end

      def init_general(dbi)
        dbi[:proj] = PROJ
        dbi[:site_id] = dbi[:ins_id] = dbi[:id]
        dbi[:frm_site] ||= dbi[:id]
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
