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
        if (dom = doc[:domain])
          init_command(dom, dbi)
          init_status(dom, dbi)
          init_watch(doc, dbi)
        end
        dbi
      end

      # Command Domain
      def init_command(dom, dbi)
        @idx = {}
        @units = {}
        return self unless dom.key?(:alias)
        arc_unit(dom[:alias])
        dbi[:command] = { alias: @idx }
        self
      end

      # identical with App::Db#arc_unit()
      def arc_unit(e)
        return unless e
        e.each do|e0|
          case e0.name
          when 'unit'
            uid = e0.attr2item(@units)
            e0.each do|e1|
              id = arc_command(e1)
              @idx[id][:unit] = uid
              (@units[uid][:members] ||= []) << id
            end
          when 'item'
            arc_command(e0)
          end
        end
        self
      end

      def arc_command(e0)
        id = e0.attr2item(@idx)
        e0.each do|e1|
          (@idx[id][:argv] ||= []) << e1.text
        end
        id
      end

      # Status Domain
      def init_status(dom, dbi)
        hst = dbi[:status] = {}
        grp = hst[:group] = {}
        (dom[:status] || []).each do|e0|
          p = (hst[e0.name.to_sym] ||= {})
          case e0.name
          when 'alias'
            e0.attr2item(p)
            ag = (grp[:alias] ||= { caption: 'Alias', members: [] })
            ag[:members] << e0['id']
          else
            e0.attr2item(p, :ref)
          end
        end
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
