#!/usr/bin/ruby
require 'libappdb'

module CIAX
  # Instance Layer
  module CmdAlias
    # Instance DB
    class Db < Db
      def initialize
        super('cdb')
      end

      private

      # doc is <project>
      # return //project/group/instance
      def doc_to_db(doc)
        dbi = super
        init_command(dbi)
        _add_group(doc[:group])
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
#        ref = itm.delete(:ref)
#        itm.update(@idx[ref].pick([:parameters, :body]))
        e0.each do|e1|
          (itm[:argv] ||= []) << e1.text
        end
        [id, itm]
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
