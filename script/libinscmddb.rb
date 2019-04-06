#!/usr/bin/env ruby
require 'libdbtree'

module CIAX
  # Instance Layer
  module Ins
    # This is part of Instance DB
    # You need add <command ref='*'/> in InsDB to use it
    class CmdDb < Dbx::Tree
      def initialize
        super('cdb')
      end

      # Cover Ins DB (dst is overridden by self)
      # Add error handling for no key
      def override(id, cdb)
        if (cref = ref(id))
          ali = cref[:command]
          %i(group unit).each { |k| cdb[k].update(ali[k]) }
          ___conv_index(cdb, ali)
        end
        self
      end

      private

      def _doc_to_db(doc)
        dbi = super
        _init_command_db(dbi, doc[:top])
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
          itm.update(idx[itm[:ref]].pick(%i(parameters body)))
        end
        idx.update(aidx)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = CmdDb.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
