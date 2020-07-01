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
        @db = type?(@cfg[:db], Ins::Db)
        _init_subdic(Frm)
        @run_list = @db.runlist_ins(@cfg.opt.proper?)
        @cfg[:sdb] = Sym::Db.new
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Conf.new('[id]', options: 'cehl') do |cfg|
        ExeDic.new(cfg, db: Ins::Db.new(cfg.proj))
      end.cui
    end
  end
end
