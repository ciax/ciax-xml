#!/usr/bin/ruby
require 'libdbtree'

module CIAX
  # Instance Layer
  module Cmd
    # Instance DB
    class Db < DbTree
      def initialize
        super('cdb')
      end

      # Cover Ins DB (dst is overridden by self)
      def cover(id, cdb)
        ali = get(id)[:command]
        %i(group unit).each { |k| cdb[k].update(ali[k]) }
        ___conv_index(cdb, ali)
        self
      end

      private

      def _doc_to_db(doc)
        dbi = super
        _init_command(dbi, doc[:top])
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        e0.each do |e1|
          itm.get(:argv) { [] } << e1.text
        end
        [id, itm]
      end

      def ___conv_index(cdb, ali)
        idx = cdb[:index]
        aidx = ali[:index]
        aidx.each do |_id, itm|
          ref = itm.delete(:ref)
          itm.update(idx[ref].pick(%i(parameters body)))
        end
        idx.update(aidx)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
