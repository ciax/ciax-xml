#!/usr/bin/env ruby
require 'libappexe'
# CIAX-XML
module CIAX
  # Application Layer
  module App
    deep_include(Site)
    # Application ExeDic
    class ExeDic
      # spcfg must have [:db]
      def initialize(spcfg, atrb = Hashx.new)
        super
        _store_db(type?(@cfg[:db], Ins::Db)) do |db|
          db.valid_ins.trues
        end
        _init_subdic(Frm)
        @cfg[:sdb] = Sym::Db.new
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        ExeDic.new(cfg, db: Ins::Db.new(cfg.proj))
      end.cui
    end
  end
end
