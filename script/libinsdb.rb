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
        if (dom = doc[:domain])
          init_command(dom, dbi)
          init_status(dom, dbi)
          init_watch(dom, dbi)
        end
        dbi
      end

      # Command Domain
      def init_command(dom, dbi)
        return self unless dom.key?(:alias)
        cdb = dbi[:command]
        @idx = cdb[:index]
        agrp = cdb[:group]['gal'] = Hashx.new
        agrp[:caption] = 'Alias'
        @umem =  agrp[:units] = []
        @units = cdb[:unit]
        @gmem = agrp[:members] = []
        _add_unit(dom[:alias])
        self
      end

      # identical with App::Db#_add_unit()
      def _add_unit(e)
        return unless e
        e.each do|e0|
          case e0.name
          when 'unit'
            uid = e0.attr2item(@units)
            @umem << uid
            e0.each do|e1|
              id = _add_item(e1)
              @idx[id][:unit] = uid
              (@units[uid][:members] ||= []) << id
            end
          when 'item'
            _add_item(e0)
          end
        end
        self
      end

      def _add_item(e0)
        id = e0.attr2item(@idx)
        @gmem << id
        item = @idx[id]
        ref = item.delete(:ref)
        item.update(@idx[ref].pick([:parameters, :body]))
        e0.each do|e1|
          (item[:argv] ||= []) << e1.text
        end
        id
      end

      # Status Domain
      def init_status(dom, dbi)
        hst = (dbi[:status] ||= {})
        grp = (hst[:group] ||= {})
        (dom[:status] || []).each do|e0|
          p = (hst[e0.name.to_sym] ||= {})
          case e0.name
          when 'alias'
            e0.attr2item(p)
            ag = (grp[:alias] ||= { caption: 'Alias', members: [] })
            ag[:members] << e0['id']
          else # group, index
            e0.attr2item(p, :ref)
          end
        end
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
