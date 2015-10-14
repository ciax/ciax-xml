#!/usr/bin/ruby
require 'libappdb'

module CIAX
  module Ins
    class Db < Db
      include Wat::Db
      def initialize(proj = PROJ)
        super('idb', proj)
        @adb = App::Db.new
      end

      # overwrite App::Db
      def get(id = nil)
        dbi = super
        dbi.cover(@adb.get(dbi['app_id']))
      end

      private

      def doc_to_db(doc)
        dbi = Dbi[doc[:attr]]
        init_command(doc,dbi)
        init_status(doc,dbi)
        dbi
      end

      # Command Domain
      def init_command(doc,dbi)
        hcmd = dbi[:command] = {}
        (doc[:domain]['alias'] || []).each do|e0|
          case e0.name
          when 'item'
            e0.attr2item(hcmd[:alias] ||= {})
            e0.each do|e1|
              (hcmd[:alias][e0['id']]['argv'] ||= []) << e1.text
            end
          when 'unit'
          end
        end
      end

      # identical with App::Db#arc_unit()
      def arc_unit(e0, idx, grp, units)
        e.each do|e0|
          case e0.name
          when 'unit'
            uid = e0.attr2item(units)
            e0.each do|e1|
              id = arc_command(e1, idx)
              (units[uid][:members] ||= []) << id
              idx[id]['unit'] = uid
              (grp[:members] ||= []) << id
            end
          when 'item'
            id = arc_command(e0, idx)
            (grp[:members] ||= []) << id
          end
        end
        idx
      end

      # Status Domain
      def init_status(doc,dbi)
        hst = dbi[:status] = {}
        grp = hst[:group] = {}
        (doc[:domain]['status'] || []).each do|e0|
          p = (hst[e0.name.to_sym] ||= {})
          case e0.name
          when 'alias'
            e0.attr2item(p)
            ag = (grp['alias']||= {'caption' => 'Alias',:members =>[]})
            ag[:members]  << e0['id']
          else
            e0.attr2item(p, 'ref')
          end
        end
        init_watch(doc, dbi)
        dbi['proj'] = @proj
        dbi['site_id'] = dbi['ins_id'] = dbi['id']
        dbi['frm_site'] ||= dbi['id']
      end

    end

    if __FILE__ == $PROGRAM_NAME
      begin
        dbi = Db.new(ARGV.shift).get(ARGV.shift)
      rescue
        Msg.usage('(opt) [id] (key) ..')
      end
      puts dbi.path(ARGV)
    end
  end
end
