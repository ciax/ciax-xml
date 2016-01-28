#!/usr/bin/ruby
require 'libdb'

module CIAX
  # Instance Layer
  module Cmd
    # Instance DB
    class Db < Db
      def initialize
        super('cdb')
      end

      # Cover Ins DB
      def cover(id, cdb)
        ali = get(id)[:command]
        %i( group unit).each { |k| cdb[k].update(ali[k]) }
        _conv_index(cdb, ali)
        self
      end

      private

      def doc_to_db(doc)
        dbi = super
        init_command(dbi)
        _add_group(doc[:top])
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        e0.each do|e1|
          (itm[:argv] ||= []) << e1.text
        end
        [id, itm]
      end

      def _conv_index(cdb, ali)
        idx = cdb[:index]
        aidx = ali[:index]
        aidx.each do |_id, itm|
          ref = itm.delete(:ref)
          itm.update(idx[ref].pick([:parameters, :body]))
        end
        idx.update(aidx)
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
