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
        sdb = (dbi[:status] ||= {})
        grp = (sdb[:group] ||= {})
        idx = (sdb[:index] ||= {})
        (doc[:status] || []).each do|e0|
          p = (sdb[e0.name.to_sym] ||= {})
          case e0.name
          when 'symtbl'
            sdb[:symtbl] << e0['ref']
          else # group, index
            e0.attr2item(p, :ref)
            e0.each do |e1|
              e1.attr2item(idx)
              ag = grp[e0[:ref]]
              (ag[:members] ||= []) << e1['id']
            end    
          end
        end
        sdb
      end
      
      def init_general(dbi)
        dbi[:proj] = ENV['PROJ']
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
